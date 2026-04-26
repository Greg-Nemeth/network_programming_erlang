# TCP Chat System

A distributed, multi-user chat system built with Erlang/OTP, featuring a central server and a polished CLI client.

## System Architecture

The project is structured as an Erlang umbrella project consisting of three primary applications:

1.  **`chat_server`**: Manages user registration, socket lifecycle, and message broadcasting.
2.  **`chat_client`**: A CLI application providing a rich user interface with ANSI-powered line reformatting.
3.  **`chat_proto`**: A shared library containing the binary protocol logic and shared types.

---

### 1. Chat Server Architecture

The server utilizes a robust supervision tree to manage high-concurrency TCP connections and global state.

```text
chat_server_sup (one_for_all)
│
├── pg (scope: chat_clients)        <-- Manages process groups for broadcasting
│
├── chat_server_conn_sup            <-- simple_one_for_one supervisor for handlers
│   └── chat_server_connection      <-- (Dynamic) One per connected client
│
├── chat_server_registry            <-- Central registry (ETS + pg monitoring)
│
└── chat_server_acceptor            <-- Listens on port 4000 & accepts connections
```

*   **`chat_server_acceptor`**: Listens for new TCP connections. On success, it delegates the socket to a new `chat_server_connection` process.
*   **`chat_server_connection`**: A `gen_server` that owns a specific client socket. It handles low-level TCP framing and interacts with the registry.
*   **`chat_server_registry`**: Manages the mapping between usernames and PIDs using an ETS table (`chat_users`). It monitors the `pg` group to automatically clean up the registry when clients disconnect.

---

### 2. Chat Client Architecture

The client is designed to provide a "modern" chat experience in a standard terminal by decoupling input from network events.

```text
       [ Terminal Stdin ]
               |
               v
    +-----------------------+
    |      input_loop       |  <-- Blocked on io:get_line/1
    +-----------+-----------+
                | {user_input, Text}
                v
    +-----------------------+           +-----------------------+
    |   chat_client_shell   | <-------> |      TCP Socket       |
    +-----------+-----------+           +-----------------------+
                |
                v
       [ Terminal Stdout ]
    (Uses ANSI Escape Codes)
```

*   **Decoupled Input**: A dedicated `input_loop` process captures user keystrokes without blocking the main `chat_client_shell` process from receiving incoming network messages.
*   **UI Engine**: The shell uses ANSI escape sequences (`\e[2K`, `\e[1A`) to clear the prompt and reformat the terminal on the fly. This allows received messages to appear "above" the current input line seamlessly.

---

### 3. Binary Protocol (`chat_proto`)

The system uses a custom binary protocol for efficient communication:

*   **Register (Tag 1)**: `[1][UsernameLen:16][Username:Binary]`
*   **Broadcast (Tag 2)**: `[2][FromLen:16][From:Binary][ContentLen:16][Content:Binary]`

---

## Getting Started

### Build
```bash
rebar3 compile
```

### Run Server
```bash
rebar3 shell --name server@127.0.0.1 --apps chat_server
```

### Run Client
In a separate terminal:
```bash
rebar3 shell --name client1@127.0.0.1 --apps chat_client
```

## Testing
The project includes a comprehensive integration suite that verifies registration limits, duplicate username handling, and broadcast delivery across multiple simulated clients.

```bash
rebar3 ct
```
