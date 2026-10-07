#include <iostream>
#include <windows.h>
#include <wininet.h>

bool checkInternetConnection() {
    BOOL bConnected = InternetCheckConnectionW(
        L"https://www.google.com",
        FLAG_ICC_FORCE_CONNECTION,
        0
    );
    return (bConnected == TRUE);
}

int main() {
    std::cout << "Checking internet connection..." << std::endl;
    if (checkInternetConnection()) {
        std::cout << "[SUCCESS] Connected to the internet (google.com is reachable)." << std::endl;
    } else {
        std::cout << "[FAILED] No internet connection or google.com is unreachable." << std::endl;
    }

    std::cout << "\nPress Enter to exit..." << std::endl;
    std::cin.get();

    return 0;
}
//g++ main-win.cpp -o check_internet-win.exe -lwininet
//./check_internet.exe