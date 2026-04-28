# TCP Chat System

A modular, distributed, multi-user chat system built with Erlang/OTP, featuring multiple server implementation strategies and a polished CLI client.

## System Architecture

The project is structured as an Erlang umbrella project, allowing for shared logic and multiple pluggable server implementations.

### Core Applications

1.  **`chat_proto`**: Shared library containing the binary protocol logic, constants, and shared types.
2.  **`chat_common`**: Contains shared server-side components used by different implementations, such as the `chat_server_registry` and `chat_server_connection` handler.
3.  **`chat_client`**: A CLI application providing a rich user interface with ANSI-powered line reformatting and decoupled input/output loops.

### Server Implementations

The system supports multiple server backends, selectable at runtime:

1.  **`chat_server`**: The reference implementation. Uses a single acceptor process to manage incoming connections and a standard supervision tree.
2.  **`chat_acceptor_pool`**: An advanced implementation (WIP) that utilizes a pool of acceptor processes to handle high-concurrency connection spikes more efficiently.
3.  **`chat_launcher`**: An orchestration application that starts the desired server implementation based on the `CHAT_IMPL` environment variable.

---

### Implementation Comparison

#### 1. Basic Server (`chat_server`)
Standard OTP supervision tree with a dedicated acceptor:
```text
chat_server_sup (one_for_all)
├── pg (scope: chat_clients)
├── chat_server_conn_sup (simple_one_for_one)
├── chat_server_registry (from chat_common)
└── chat_server_acceptor
```

#### 2. Pooled Acceptor Server (`chat_acceptor_pool`)
Designed for higher throughput by pre-spawning multiple acceptors:
```text
chat_acceptor_pool_sup (one_for_all)
├── chat_server_registry (from chat_common)
├── chat_acceptor_pool_connection_supervisor (simple_one_for_one)
└── chat_acceptor_pool_tcp_supervisor (rest_for_one)
    └── chat_acceptor_pool_listener
        └── chat_acceptor_pool_acceptor_supervisor (Pool of N acceptors)
```

---

## Binary Protocol (`chat_proto`)

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
You can launch the default server or specify an implementation via `CHAT_IMPL`:

**Default (chat_server):**
```bash
rebar3 shell --name server@127.0.0.1 --apps chat_launcher
```

**Pooled Acceptors:**
```bash
CHAT_IMPL=POOL rebar3 shell --name server@127.0.0.1 --apps chat_launcher
```

### Run Client
In a separate terminal:
```bash
rebar3 shell --name client1@127.0.0.1 --apps chat_client
```

## Testing
The project includes a comprehensive integration suite that verifies registration limits, duplicate username handling, and broadcast delivery.

```bash
rebar3 ct
```
