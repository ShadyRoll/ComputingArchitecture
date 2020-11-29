#include <iostream>
#include <algorithm>
#include <ctime>
#include <fstream>
#include <omp.h>

using namespace std;

// Согласные
static const string consonants = "pbkfvmzhtdln";
// Гласные
static const string vowels = "aeiouy";

/**
 * Книга
 */
class Book {
public:
    /**
     * Дефолтный конструктор
     */
    Book() = default;

    /**
     * Создает книгу со случайными автором, заголовком и количеством страниц
     * @param rowNum - номер ряда
     * @param cupboardNum  - номер шкафа
     * @param pos - позиция (номер книги в шкафу)
     */
    Book(int rowNum, int cupboardNum, int pos) {
        this->rowNum = rowNum;
        this->cupboardNum = cupboardNum;
        this->pos = pos;
        author = genRndName() + " " + genRndName();
        title = genRndName();
        numberOfPages = rand() % 1000 + 1;
    }

    /**
     * Передает данные о книге в поток
     * @return книга в формате (автор, заголовок, количество страниц)
     */
    friend ostream &operator<<(ostream &os, const Book &book) {
        os << "(" << book.author << ", " << book.title << ", " << book.numberOfPages <<
           ") pos = (" << book.rowNum << ", " << book.cupboardNum <<
           ", " << book.pos << ")";
        return os;
    }

    /**
     * Оператор сравнения для сортировки
     * Справнивает лексиграфически сначала по автору, потом по
     * названию, далее по количеству страниц
     * @param book - книга, с которой производится сравнение
     * @return "меньше" ли книга, чем данная
     */
    bool operator<(const Book &book) {
        if (author == book.author) {
            if (title == book.title)
                return numberOfPages < book.numberOfPages;
            return title < book.title;
        }
        return author < book.author;
    }

private:
    /**
     * Генерирует случаное название (или имя)
     * @return случайное название
     */
    static string genRndName() {
        // Количество слогов после 1й буквы
        int len;
        // Название
        string str;

        // Генерирует количетсво слогов
        len = rand() % 5 + 1;
        // Генерируем 1ю заглавную букву
        str = (rand() % ('Z' - 'A')) + 'A';
        // Генерируем слоги
        for (int i = 0; i < len; ++i) {
            str += consonants[rand() % consonants.size()];
            str += vowels[rand() % vowels.size()];
        }
        return str;
    }

    // Автор
    string author;
    // Заголовок
    string title;
    // Количество страниц
    int numberOfPages{};
    // Номер ряда
    int rowNum{};
    // Номер шкафа
    int cupboardNum{};
    // Позиция (номер книги в шкафу)
    int pos{};
};

// Массив книг (библиотека)
Book ***library;

// Каталог книг
Book *catalog;

// Количество рядов
int M;
// Количество шкафов в ряду
int N;
// Количество книг в каждом шкафу
int K;

// Файловые потоки
ifstream in{"input.txt"};
ofstream out{"output.txt"};

/**
 * Инициализирует библиотеку
 */
void initLibrary() {
    library = new Book **[M];
    for (int i = 0; i < M; ++i) {
        library[i] = new Book *[N];
        for (int j = 0; j < N; ++j) {
            library[i][j] = new Book[K];
        }
    }
}

/**
 * Очищает библиотеку и каталог
 */
void deleteLibraryAndCatalog() {
    // Очищаем каждый шкаф, каждый ряд
    for (int i = 0; i < M; ++i) {
        for (int j = 0; j < N; ++j)
            delete[] library[i][j];
        delete[] library[i];
    }
    delete[] library;
    delete[] catalog;
}

/**
 * Генерирует книги библиотеки
 * @param M - количетсво рядов
 * @param N - колчиетсво шкафов в ряду
 * @param K - количество книг в шкафу
 */
void generateLibrary() {
    // Инициализируем массив книг
    initLibrary();

    // Номер потока
    int threadNum;
    hash<int> hasher;
    #pragma omp parallel for default(none) private(threadNum) \
        shared(catalog, library, N, M, K, out, hasher)
    for (int i = 0; i < M; ++i) {
        threadNum = omp_get_thread_num();
        /* Устанавливаем seed рандома текущим системным
         * временем xor хешированный номер потока (чтобы каждый поток
         * генерировал уникальные значения случайные значения) */
        srand(clock() ^ hasher(threadNum));

        for (int j = 0; j < N; ++j) {
            for (int k = 0; k < K; ++k) {
                library[i][j][k] = Book(i, j, k);
                #pragma omp critical
                {
                    out << "Thread" << threadNum << " generated book "
                        << library[i][j][k] << endl;
                }
            }
        }
    }
}

/**
 * Составляет каталог библиотеки
 */
void generateCatalog() {
    catalog = new Book[N * M * K];
    // Номер потока
    int threadNum;
    // Параллельно проходимся по библиотеке и заносим записи в каталог
    #pragma omp parallel for default(none) private(threadNum) \
        shared(catalog, library, N, M, K, out)
    for (int i = 0; i < M; ++i) {
        threadNum = omp_get_thread_num();
        for (int j = 0; j < N; ++j) {
            for (int k = 0; k < K; ++k) {
                catalog[i * N * K + j * K + k] = library[i][j][k];
                #pragma omp critical
                {
                    out << "Thread" << threadNum << " added book "
                        << library[i][j][k] << " to catalog" << endl;
                }
            }
        }
    }

    // Сортируем каталог в основном потоке
    sort(catalog, catalog + (N * M * K));

    // Выводим каталог
    out << "Sorted catalog:" << endl;
    for (int i = 0; i < M * N * K; ++i) {
        out << catalog[i] << endl;
    }
}

/**
 * Главная точка входа в программу
 */
int main() {
    // Считываем данные из входного файла
    in >> M >> N >> K;

    // Проверка корректности ввода
    if (M <= 0 || N <= 0 || K <= 0) {
        out << "M, N and K must be positive integers!" << endl;
        return 0;
    }

    // Генерируем библиотеку (массив книг)
    generateLibrary();
    // Генерируем каталог
    generateCatalog();

    // Очищаем библиотеку и каталог
    deleteLibraryAndCatalog();

    // Закрываем потоки
    in.close();
    out.close();

    return 0;
}