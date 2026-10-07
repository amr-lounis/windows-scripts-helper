#include <iostream>
#include <cstring>

#if defined(_WIN32) || defined(_WIN64)
    #include <winsock2.h>
    #include <ws2tcpip.h>
    #pragma comment(lib, "ws2_32.lib")
#else
    #include <sys/socket.h>
    #include <arpa/inet.h>
    #include <netdb.h>
    #include <unistd.h>
    #define SOCKET int
    #define INVALID_SOCKET -1
    #define SOCKET_ERROR -1
    #define closesocket(s) close(s)
#endif

bool checkInternetConnection() {
#if defined(_WIN32) || defined(_WIN64)
    WSADATA wsaData;
    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        return false;
    }
#endif

    struct addrinfo hints{}, *res = nullptr;
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;

    if (getaddrinfo("google.com", "80", &hints, &res) != 0) {
#if defined(_WIN32) || defined(_WIN64)
        WSACleanup();
#endif
        return false;
    }

    SOCKET sock = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (sock == INVALID_SOCKET) {
        freeaddrinfo(res);
#if defined(_WIN32) || defined(_WIN64)
        WSACleanup();
#endif
        return false;
    }

    bool isConnected = false;
    if (connect(sock, res->ai_addr, (int)res->ai_addrlen) != SOCKET_ERROR) {
        isConnected = true;
    }

    closesocket(sock);
    freeaddrinfo(res);

#if defined(_WIN32) || defined(_WIN64)
    WSACleanup();
#endif

    return isConnected;
}

int main() {
    std::cout << "Checking internet connection (google.com)..." << std::endl;

    if (checkInternetConnection()) {
        std::cout << "[SUCCESS] Internet is connected." << std::endl;
    } else {
        std::cout << "[FAILED] No internet connection." << std::endl;
    }

    std::cout << "\nPress Enter to exit..." << std::endl;
    std::cin.get();

    return 0;
}
//win -> g++ main-cross.cpp -o check_internet-cross.exe -lws2_32
//linux -> g++ main-cross.cpp -o check_internet-cross