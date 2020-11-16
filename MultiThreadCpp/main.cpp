#include <iostream>
#include <vector>
#include <ctime>
#include <pthread.h>
#include <fstream>

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
     * Создает книгу со случайными автором, заголовком и количеством страниц
     */
    Book() {
        author = genRndName() + " " + genRndName();
        title = genRndName();
        numberOfPages = rand() % 1000 + 1;
    }

    /**
     * Передает данные о книге в поток
     * @return книга в формате (автор, заголовок, количество страниц)
     */
    friend ostream &operator<<(ostream &os, const Book &book) {
        os << "(" << book.author << ", " << book.title << ", " << book.numberOfPages << ")";
        return os;
    }

private:
    /**
     * Генерирует случаное название
     * @return случайное навзание
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
    int numberOfPages;
};

// Массив книг (библиотека)
Book ***library;
// Потоки
pthread_t *threads;
// Мьютекс для критической секции
pthread_mutex_t mutex;

vector<int *> tasks;

/**
 * Выполняет задачи из протфеля:
 * Заполняет ячейки массива книг книгами
 */
void *fillWorker(void *arg) {
    // Индекс книги
    int *index;

    // Берем задачи из портфеля, пока он не пуст
    while (true) {
        // Блокируем критическую секцию
        pthread_mutex_lock(&mutex);
        // Если задач в портфлеле нет - выходим
        if (tasks.empty()) {
            pthread_mutex_unlock(&mutex);
            return nullptr;
        }
        // Получаем индекс книги
        index = tasks.back();
        // Удаляем задачу из протфеля
        tasks.pop_back();
        // Разблокируем критическую секцию
        pthread_mutex_unlock(&mutex);
        // Помещаем в массив новую книгу
        library[index[0]][index[1]][index[2]] = Book();

        delete[] index;
    }
}

/**
 * Главная точка входа в программу
 */
int main() {
    // Количество потоков (включая основной)
    const int NUM_OF_THREADS = 4;
    // Количество рядов
    int M;
    // Количество шкафов в ряду
    int N;
    // Количество книг в каждом шкафу
    int K;

    // Инициируем файловые потоки (они закроются автоматически)
    ifstream in{"input.txt"};
    ofstream out{"output.txt"};

    // Считываем данные из входного файла
    in >> M >> N >> K;

    // Проверка корректности ввода
    if (M <= 0 || N <= 0 || K <= 0) {
        out << "M, N and K must be positive integers!" << endl;
        return 0;
    }

    /* Устанавливаем seed рандома текущим системным временем
     (чтобы каждый раз генерировать новые случайные значения) */
    srand(clock());

    // Заполняем портфель задач, параллельно инициируя массив книг
    library = new Book **[M];
    for (int i = 0; i < M; ++i) {
        library[i] = new Book *[N];
        for (int j = 0; j < N; ++j) {
            library[i][j] = new Book[K];
            for (int k = 0; k < K; ++k) {
                tasks.push_back(new int[3]{i, j, k});
            }
        }
    }

    // Инициируем мьютекс
    pthread_mutex_init(&mutex, nullptr);

    // Инициализируем массив потоков
    threads = new pthread_t[NUM_OF_THREADS - 1];
    // Запускаем потоки
    for (int i = 0; i < NUM_OF_THREADS - 1; ++i) {
        pthread_create(&threads[i], nullptr, fillWorker, (void *) (nullptr));
    }
    // Запускаем также в основном потоке
    fillWorker(nullptr);
    // Ожидаем завершения всех потоков
    for (int i = 0; i < NUM_OF_THREADS - 1; ++i) {
        pthread_join(threads[i], nullptr);
    }

    delete[] threads;

    // Выводим полученные данные
    for (int i = 0; i < M; ++i) {
        out << "Row " << i + 1 << ":" << endl;
        for (int j = 0; j < N; ++j) {
            out << "-Cupboard " << j + 1 << ": ";
            for (int k = 0; k < K; ++k) {
                out << library[i][j][k] << ((k != K - 1) ? ", " : "\n");
            }
            // После вывода очищаем массив
            delete[] library[i][j];
        }
        delete[] library[i];
    }
    delete[] library;

    return 0;
}