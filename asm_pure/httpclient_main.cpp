#include <iostream>

extern "C" long long http_client_get(
    const char* ip,
    int port,
    const char* path,
    char* out,
    int out_capacity
);

int main(int argc, char** argv) {
    const char* ip = "127.0.0.1";
    const int port = 18081;
    const char* path = argc > 1 ? argv[1] : "/";
    char response[4096]{};

    std::cout << "HTTP client scenario" << std::endl;
    std::cout << "request = http://" << ip << ":" << port << path << std::endl;

    long long bytes = http_client_get(ip, port, path, response, sizeof(response) - 1);
    std::cout << "bytes = " << bytes << std::endl;

    if (bytes < 0) {
        std::cout << "request failed" << std::endl;
        return 1;
    }

    response[bytes] = '\0';
    std::cout << "response:" << std::endl;
    std::cout << response << std::endl;
    return 0;
}
