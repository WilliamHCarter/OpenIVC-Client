#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include "client.h"

// Define function pointers for ts3client methods
typedef int (*ts3client_init)(const struct ClientUIFunctions* functionPointers, int port, int two, int three, const char* resourcesFolder);
typedef int (*ts3client_spawnNewServerConnectionHandler)(int port, unsigned long long* result);

typedef int (*ts3client_startConnection)(unsigned long long serverConnectionHandlerID, 
    const char* identity, const char* ip, unsigned int port, const char* nickname, 
    const char** defaultChannelArray, const char* defaultChannelPassword, const char* serverPassword);

struct ConnectInfo {
    char* ip;
    unsigned short port;
};

int startClient() {
    // Load the DLL
    printf("Loading DLL.\n");

    HMODULE hDll = LoadLibraryA("ts3client.dll");
    if (hDll == NULL) {
        DWORD error = GetLastError();
        printf("Error code: %lu\n", error);
        printf("Failed to load ts3client.dll\n");
        return -1;
    }

    printf("DLL loaded successfully.\n");

    // Get function pointers
    ts3client_init initLibrary = (ts3client_init)GetProcAddress(hDll, "ts3client_initClientLib");

    if (!initLibrary) {
        printf("Failed to load initLibrary.\n");
        FreeLibrary(hDll);
        return -1;
    }

    void* funcs;
    memset(&funcs, 1, 8);
    const char* backend = "SoundBackends";
    unsigned int error = initLibrary(&funcs, 0, 0, 0, backend);
    unsigned long long scHandlerID;

    // Get function pointers
    ts3client_spawnNewServerConnectionHandler newConnHandler = (ts3client_spawnNewServerConnectionHandler)GetProcAddress(hDll, "ts3client_spawnNewServerConnectionHandler");

    if (!newConnHandler) {
        printf("Failed to load newConnHandler.\n");
        FreeLibrary(hDll);
        return -1;
    }

    /* Spawn a new server connection handler using the default port and store the server ID */
    if ((error = newConnHandler(0, &scHandlerID)) != 0) {
        printf("Error spawning server connection handler: %d\n", error);
        return 1;
    }

    /* Get default capture mode */

    /* Get default capture device */
    
    /* Check for commandline parameters <ip> <port> */
    struct ConnectInfo connect_info;
    connect_info.ip = "localhost";
    connect_info.port = 9989;


    // Get function pointers
    ts3client_startConnection connect = (ts3client_startConnection)GetProcAddress(hDll, "ts3client_startConnection");

    if (!connect) {
        printf("Failed to load connect.\n");
        FreeLibrary(hDll);
        return -1;
    }
    char identity[1024] = { 0 };
    printf("Connecting to %s:%d\n", connect_info.ip, connect_info.port);
    /* Connect to server on localhost:9987 with nickname "client", no default channel, no default channel password and server password "secret" */
    error = connect(scHandlerID, identity, connect_info.ip, connect_info.port, "client", NULL, "", "");
    printf("%d", error);

    if (error != 0) {
        printf("Error connecting to server: %d\n", error);
        return 1;
    }
    // Free the DLL
    FreeLibrary(hDll);
    return 0;
}
