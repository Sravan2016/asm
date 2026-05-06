#include <iostream>

extern "C" long long http_server_once(int port, const char* response_body);
extern "C" long long http_server_forever(
    int port,
    const char* response_body,
    void (*on_request)(const char*, int)
);

extern "C" void print_request(const char* data, int bytes) {
    std::cout << "client message bytes = " << bytes << std::endl;
    std::cout.write(data, bytes);
    std::cout << std::endl;
    std::cout.flush();
}

int main() {
    const int port = 18081;
    const char* body = "hello from asm http server";

    std::cout << "HTTP server scenario" << std::endl;
    std::cout << "listening port = " << port << std::endl;
    std::cout << "server always on, press Ctrl+C to stop" << std::endl;

    long long ok = http_server_forever(port, body, print_request);

    std::cout << "server result = " << ok << std::endl;
    return ok ? 0 : 1;
}
