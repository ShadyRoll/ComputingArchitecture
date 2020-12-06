#include <iostream>
#include <vector>
#include <pthread.h>
#include <fstream>

using namespace std;

// Высота грядки
int N;
// Ширина грядки
int M;
// План обработки грядки
vector<vector<char>> plan;
// Грядка
vector<vector<char>> garden;
// Мьютексы для каждой ячейки грядки
vector<vector<pthread_mutex_t>> mutexes;
// Мьютекс для вывода
pthread_mutex_t writeMutex;

// Инициируем файловые потоки (они закроются автоматически)
ifstream in{"input.txt"};
ofstream out{"output.txt"};

/**
 * Запускает обработку грядки
 * @param args - массив из 4х агурментов (стартовая позиция по X,
 * стартовая позиция по Y, сдвиг по Х за шаг, сдвиг по Y за шаг)
 * @return
 */
void *doGardenWork(void *args) {
    // Переводим тип аргументов в int
    int *intArgs = (int *) args;
    // Стартовая позиция
    int startPosX = intArgs[0];
    int startPosY = intArgs[1];
    // Шаг
    int moveX = intArgs[2];
    int moveY = intArgs[3];

    // Проверка аргументов
    if (startPosX < 0 || startPosX >= M || startPosY < 0 || startPosY >= N)
        throw invalid_argument("Invalid start position.");
    if (moveX == 0 && moveY == 0)
        throw invalid_argument("moveX and moveY can't be 0 at the same time.");

    // Текущая позиция
    int x;
    int y;
    // Суммарное смешение за все шаги
    int distX = 0, distY = 0;
    // Количество шагов (нужно пройти всю грядку)
    int workTicks = N * M / (abs(moveX) + abs(moveY));

    // Проходимя по участках грядки
    for (int i = 0; i < workTicks; ++i, distX += moveX, distY += moveY) {
        // Сколько полных рядов уже пройдено
        int xRows = distX / M;
        int yRows = distY / N;
        // Вычисляем текущий участок грядки
        x = (startPosX + distX + yRows) % M;
        y = (startPosY + distY + xRows) % N;
        if (x < 0)
            x += M;
        if (y < 0)
            y += N;

        // Блокируем этот участок грядки
        pthread_mutex_lock(&mutexes[y][x]);
        // Если участок еще не был обработан
        if (garden[y][x] == -1) {
            // "Обрабатываем" участок согласно плану
            garden[y][x] = plan[y][x];
            // Выводим информацию о выполенной обработке участка
            pthread_mutex_lock(&writeMutex);
            out << "Gardener " << pthread_self() << " handles place (" <<
                x << ", " << y << ")" << endl;
            pthread_mutex_unlock(&writeMutex);
        }
        // Освобождаем участок грядки
        pthread_mutex_unlock(&mutexes[y][x]);
    }

    return nullptr;
}

/**
 * Главная точка входа в программу
 */
int main() {
    // Считываем высоту и ширину грядки из входного файла
    in >> N >> M;

    // Проверка корректности ввода
    if (M <= 0 || N <= 0) {
        out << "M and N must be positive integers!" << endl;
        return 0;
    }

    // Инициализируем переменные
    plan = vector<vector<char>>(N, vector<char>(M));
    garden = vector<vector<char>>(N, vector<char>(M));
    mutexes = vector<vector<pthread_mutex_t>>(N, vector<pthread_mutex_t>(M));
    pthread_mutex_init(&writeMutex, nullptr);
    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < M; ++j) {
            // Считываем план
            in >> plan[i][j];
            garden[i][j] = -1;
            pthread_mutex_init(&mutexes[i][j], nullptr);
        }
    }

    // Поток для 2го садовника
    pthread_t thread;

    // Аргументы для 1го садовника (старт в левом верхнем углу, движение слева направо)
    int *args1 = new int[4]{0, 0, 1, 0};
    // Аргументы для 1го садовника (старт в правом нижнем углу, движение снизу вверх)
    int *args2 = new int[4]{M - 1, N - 1, 0, -1};
    // 2й садовник принимается за работу
    pthread_create(&thread, nullptr, doGardenWork, (void *) (args2));
    // 1й садовник принимается за работу
    doGardenWork((void *) (args1));

    // Ждем, пока 2й садовник завершит работу
    pthread_join(thread, nullptr);
    // Выводим грядку
    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < M; ++j) {
            out << garden[i][j] << " ";
        }
        out << endl;
    }

    delete[] args1;
    delete[] args2;
    return 0;
}
