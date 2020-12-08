#include <iostream>
#include <vector>
#include <pthread.h>
#include <fstream>

using namespace std;

enum GardenElements {
    UNHANDLED = -1,
    EMPTY,
    APPLE_TREE,
    PEAR_TREE,
    LINGONBERRY_BUSH,
    BLUEBERRY_BUSH,
    STRAWBERRY,
    NUM_OF_GARDEN_ELEMENTS
};

// Высота сада
int N;
// Ширина сада
int M;
// План обработки сада
vector<vector<GardenElements>> plan;
// Сад
vector<vector<GardenElements>> garden;
// Мьютексы для каждого участка сада
vector<vector<pthread_mutex_t>> mutexes;
// Мьютекс для вывода
pthread_mutex_t writeMutex;

// Инициируем файловые потоки (они закроются автоматически)
ifstream in{"input.txt"};
ofstream out{"output.txt"};

/**
 * Определяет название пасадки по ее типу
 * @param plant - значение (из GardenElements)
 * @return название посадки
 */
string getPlantName(GardenElements plant) {
    switch (plant) {
        case UNHANDLED:
        case EMPTY:
            return "Empty";
        case APPLE_TREE:
            return "Apple tree";
        case PEAR_TREE:
            return "Pear tree";
        case LINGONBERRY_BUSH:
            return "Lingonberry bush";
        case BLUEBERRY_BUSH:
            return "Blueberry bush";
        case STRAWBERRY:
            return "Strawberry";
        default:
            throw invalid_argument("Unknown plant type.");
    }
}

/**
 * Запускает обработку сада
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

    // Переменная для вывода названия посадки
    string plantName;

    // Текущая позиция
    int x;
    int y;
    // Суммарное смешение за все шаги
    int distX = 0, distY = 0;
    // Количество шагов (нужно пройти весь сад)
    int workTicks = N * M / (abs(moveX) + abs(moveY));

    // Проходимся по участкам сада
    for (int i = 0; i < workTicks; ++i, distX += moveX, distY += moveY) {
        // Сколько полных рядов уже пройдено
        int xRows = distX / M;
        int yRows = distY / N;
        // Вычисляем текущий участок сада
        x = (startPosX + distX + yRows) % M;
        y = (startPosY + distY + xRows) % N;
        if (x < 0)
            x += M;
        if (y < 0)
            y += N;

        // Блокируем этот участок сада
        pthread_mutex_lock(&mutexes[y][x]);
        // Если участок еще не был обработан
        if (garden[y][x] == UNHANDLED) {
            // "Обрабатываем" участок согласно плану
            garden[y][x] = plan[y][x];
            // Получаем название посадки
            plantName = getPlantName(garden[y][x]);
            // Выводим информацию о выполенной обработке участка
            pthread_mutex_lock(&writeMutex);
            out << "Gardener " << pthread_self() << " handled square (" <<
                x << ", " << y << ") -> " << plantName << endl;
            pthread_mutex_unlock(&writeMutex);
        }
        // Освобождаем участок сада
        pthread_mutex_unlock(&mutexes[y][x]);
    }

    return nullptr;
}

/**
 * Главная точка входа в программу
 */
int main() {
    // Считываем высоту и ширину сада из входного файла
    in >> N >> M;

    // Проверка корректности ввода
    if (M <= 0 || N <= 0) {
        out << "M and N must be positive integers!" << endl;
        return 0;
    }

    // Инициализируем переменные
    plan = vector<vector<GardenElements>>(N, vector<GardenElements>(M, UNHANDLED));
    garden = vector<vector<GardenElements>>(N, vector<GardenElements>(M, UNHANDLED));
    mutexes = vector<vector<pthread_mutex_t>>(N, vector<pthread_mutex_t>(M));
    pthread_mutex_init(&writeMutex, nullptr);

    // Переменная для ввода плана
    int elemInput;
    // Аргументы для 1го садовника (старт в левом верхнем углу, движение слева направо)
    int *args1 = new int[4]{0, 0, 1, 0};
    // Аргументы для 1го садовника (старт в правом нижнем углу, движение снизу вверх)
    int *args2 = new int[4]{M - 1, N - 1, 0, -1};

    try {
        for (int i = 0; i < N; ++i) {
            for (int j = 0; j < M; ++j) {
                // Считываем участок из плана
                in >> elemInput;
                if (elemInput < EMPTY || elemInput >= NUM_OF_GARDEN_ELEMENTS) {
                    throw invalid_argument("Invalid code of plant in plan (" + to_string(elemInput) + ").");
                }
                plan[i][j] = (GardenElements) elemInput;
                // Также инициализирует мьютекс этого участка
                pthread_mutex_init(&mutexes[i][j], nullptr);
            }
        }

        // Поток для 2го садовника
        pthread_t thread;

        // 2й садовник принимается за работу
        pthread_create(&thread, nullptr, doGardenWork, (void *) (args2));
        // 1й садовник принимается за работу
        doGardenWork((void *) (args1));

        // Ждем, пока 2й садовник завершит работу
        pthread_join(thread, nullptr);

        // Выводим сад
        out << "Garden:" << endl;
        for (int i = 0; i < N; ++i) {
            for (int j = 0; j < M; ++j) {
                out << getPlantName(garden[i][j]) << '\t';
            }
            out << endl;
        }
    }
    catch (const invalid_argument &ex) {
        // Ошибка аргумента в ходе выполнения
        out << "Invalid argument: " << ex.what() << endl;
    } catch (const exception &ex) {
        // Прочие ошибки
        out << "Error: " << ex.what() << endl;
    }

    delete[] args1;
    delete[] args2;
    return 0;
}
