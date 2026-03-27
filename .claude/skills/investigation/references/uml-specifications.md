# UML/図表ガイドライン

Mermaid形式を使用して作成する図のサンプル集。

---

## コンポーネント図（アーキテクチャ）

```mermaid
graph TD
    subgraph Presentation Layer
        A[Controller]
        B[View]
    end
    subgraph Business Layer
        C[Service]
        D[UseCase]
    end
    subgraph Data Layer
        E[Repository]
        F[Entity]
    end
    A --> C
    C --> E
    E --> F
```

## ER図（データ構造）

```mermaid
erDiagram
    USER ||--o{ ORDER : places
    USER {
        int id PK
        string name
        string email
    }
    ORDER ||--|{ ORDER_ITEM : contains
    ORDER {
        int id PK
        int user_id FK
        date created_at
    }
```

## シーケンス図（統合ポイント）

```mermaid
sequenceDiagram
    participant C as Client
    participant A as API
    participant S as Service
    participant D as Database
    
    C->>A: Request
    A->>S: Process
    S->>D: Query
    D-->>S: Result
    S-->>A: Response
    A-->>C: Response
```

## クラス図（オブジェクト構成）

```mermaid
classDiagram
    class User {
        +int id
        +string name
        +string email
        +create()
        +update()
    }
    class Order {
        +int id
        +User user
        +List~OrderItem~ items
        +place()
        +cancel()
    }
    User "1" --> "*" Order
```

## 依存関係図

```mermaid
graph LR
    subgraph External
        E1[express]
        E2[typeorm]
        E3[jest]
    end
    subgraph Internal
        I1[controllers]
        I2[services]
        I3[repositories]
    end
    I1 --> I2
    I2 --> I3
    I1 --> E1
    I3 --> E2
```

## 推奨図表マッピング

| 調査ファイル | 推奨図表 |
|--------------|----------|
| 01_architecture | コンポーネント図、レイヤー図 |
| 02_data-structure | ER図、クラス図 |
| 03_dependencies | 依存関係図 |
| 04_existing-patterns | コードサンプル（コードブロック） |
| 05_integration-points | シーケンス図、連携図 |
| 06_risks-and-constraints | リスクマトリックス、影響度図 |
