# ShopApp — CRUD Completo com Autenticação em Flutter

Aplicativo mobile desenvolvido em Flutter como atividade da disciplina **Desenvolvimento para Dispositivos Móveis II**.

O projeto consome a [DummyJSON API](https://dummyjson.com/) e implementa o ciclo completo de operações **C.R.U.D** (Create, Read, Update, Delete) com **persistência local via SQLite**, **autenticação via token JWT** e **sessão persistente**, seguindo uma arquitetura em camadas desacoplada.

---

## 📱 O que o app faz

| Operação | HTTP | Descrição |
|----------|------|-----------|
| **Login**  | POST   | Autentica o usuário via `/auth/login` e salva o token |
| **Read**   | GET    | Lista todos os produtos; exibe detalhes de cada item |
| **Create** | POST   | Cadastra novo produto via formulário |
| **Update** | PUT    | Edita produto existente via formulário pré-preenchido |
| **Delete** | DELETE | Remove produto com confirmação antes de excluir |
| **Logout** | —      | Encerra a sessão e limpa o token salvo |

- **Autenticação obrigatória**: o usuário só acessa a listagem de produtos após realizar login. A tela de splash verifica automaticamente se já existe sessão ativa.
- **Sessão persistente**: o token é salvo com `shared_preferences` e restaurado na próxima abertura do app — sem precisar logar novamente.
- **Tela de perfil**: exibe nome, e-mail, avatar e token do usuário autenticado, consumindo o endpoint `/auth/me`.
- **Persistência híbrida**: dados são buscados da API na primeira abertura e gravados no SQLite; nas sessões seguintes o app usa o banco local.
- **Sincronização manual**: botão "Sync" na listagem força nova busca da API e atualiza o banco local. Botão "Refresh" recarrega sem limpar o banco.
- **Favoritos**: cada produto pode ser marcado/desmarcado como favorito (⭐). Um filtro no topo exibe apenas os favoritos.
- **Badges de origem**: todo produto exibe um badge **API** (azul) ou **LOCAL** (verde).
- **Feedback visual**: indicadores de carregamento, SnackBars de sucesso/erro e diálogo de confirmação antes de excluir.
- **Suporte a Flutter Web**: onde o `sqflite` não é suportado, o app usa armazenamento em memória automaticamente.

---

## 🗂️ Estrutura de pastas

```
lib/
├── auth/
│   ├── models/
│   │   └── auth_user.dart             # Modelo do usuário autenticado (tokens, nome, avatar)
│   ├── services/
│   │   ├── auth_service.dart          # login() POST /auth/login | getCurrentUser() GET /auth/me
│   │   └── http_headers.dart          # Classe auxiliar para montar cabeçalhos com token Bearer
│   └── session/
│       └── session_controller.dart    # Singleton: guarda sessão em memória + persiste token
│
├── core/
│   ├── errors/
│   │   └── failure.dart               # Classe de erro customizado
│   ├── network/
│   │   └── http_client.dart           # Cliente HTTP (GET, POST, PUT, DELETE)
│   └── routes/
│       └── app_routes.dart            # Constantes de rotas nomeadas
│
├── data/
│   ├── datasources/
│   │   ├── product_local_datasource.dart   # SQLite (sqflite) + fallback em memória (Web)
│   │   └── product_remote_datasource.dart  # DummyJSON API
│   ├── models/
│   │   └── product_model.dart         # Adaptado para DummyJSON (thumbnail, rating, stock)
│   └── repositories/
│       └── product_repository_impl.dart   # Repositório híbrido (API + SQLite)
│
├── domain/
│   ├── entities/
│   │   └── product.dart               # Entidade pura de domínio
│   └── repositories/
│       └── product_repository.dart    # Contrato (interface) do repositório
│
├── presentation/
│   ├── pages/
│   │   ├── splash_page.dart           # ★ Verifica sessão salva → produtos ou login
│   │   ├── login_page.dart            # ★ Tela de login com validação e feedback
│   │   ├── profile_page.dart          # ★ Perfil do usuário autenticado + logout
│   │   ├── home_page.dart             # Tela inicial com gradiente
│   │   ├── product_page.dart          # Listagem + avatar do usuário + logout + refresh
│   │   ├── product_detail_page.dart   # Detalhes + botões Editar e Excluir
│   │   └── product_form_page.dart     # Formulário reutilizado (criar / editar)
│   └── viewmodels/
│       ├── product_state.dart         # Estado reativo (ProductStatus enum + filtro favoritos)
│       └── product_viewmodel.dart     # Lógica de negócio + CRUD + favoritos
│
└── main.dart                          # Injeção de dependências + rotas
```

> ★ Arquivos novos adicionados nesta etapa.

---

## 🔐 Fluxo de Autenticação

```
App abre
  └─► SplashPage
        ├── Token salvo? → GET /auth/me → sessão restaurada → ProductPage
        └── Sem token ou expirado → LoginPage
                                        │
                              usuário preenche credenciais
                                        │
                              POST /auth/login (DummyJSON)
                                        │
                              ┌─────────┴──────────┐
                            sucesso               erro
                              │                    │
                    salva token (shared_prefs)   SnackBar
                    salva sessão (memória)
                              │
                         ProductPage
                              │
                    [botão logout ou perfil]
                              │
                     SessionController.logout()
                     limpa token salvo
                              │
                          LoginPage
```

---

## 🧭 Rotas

| Constante | Caminho | Tela |
|-----------|---------|------|
| `AppRoutes.splash` | `/` | `SplashPage` *(nova rota inicial)* |
| `AppRoutes.login` | `/login` | `LoginPage` |
| `AppRoutes.home` | `/home` | `HomePage` |
| `AppRoutes.products` | `/products` | `ProductPage` |
| `AppRoutes.productDetail` | `/products/detail` | `ProductDetailPage` |
| `AppRoutes.productCreate` | `/products/create` | `ProductFormPage` (cadastro) |
| `AppRoutes.productEdit` | `/products/edit` | `ProductFormPage` (edição) |
| `AppRoutes.profile` | `/profile` | `ProfilePage` |

### Fluxo de navegação

```
SplashPage
  ├─► LoginPage → ProductPage (após login bem-sucedido)
  └─► ProductPage (sessão já ativa)
        ├─► ProfilePage (toque no avatar/nome)
        │     └─► LoginPage (logout)
        ├─► ProductDetailPage
        │     ├─► ProductFormPage (edição)
        │     └─► [delete com confirmação]
        └─► ProductFormPage (cadastro via FAB)
```

---

## 🏛️ Arquitetura

O projeto segue separação em quatro camadas:

```
Auth (autenticação, sessão, token)
      │
Presentation (UI + ViewModel)
      │
      ▼
Domain (entidades + contratos)
      │
      ▼
Data (datasources + repositório)
      │
      ├── ProductRemoteDatasource  →  DummyJSON API
      └── ProductLocalDatasource   →  SQLite (sqflite) | memória (Web)
```

### Camada Auth

| Classe | Responsabilidade |
|--------|-----------------|
| `AuthUser` | Modelo com id, username, email, firstName, lastName, image, accessToken, refreshToken |
| `AuthService` | Requisições HTTP de autenticação: `login()` e `getCurrentUser()` |
| `HttpHeaders` | Monta cabeçalhos `Content-Type` e `Authorization: Bearer <token>` |
| `SessionController` | Singleton — guarda o usuário em memória, persiste/lê o token via `shared_preferences` |

### Estratégia do repositório híbrido

```
getProducts()
  ├── Banco local tem dados?  →  retorna do SQLite
  └── Não  →  busca da API  →  salva no SQLite  →  retorna

createProduct()  →  POST na API  →  insere no SQLite  (fallback: só SQLite)  →  isLocal = true
updateProduct()  →  PUT na API   →  atualiza SQLite   (fallback: só SQLite)
deleteProduct()  →  DELETE na API →  remove do SQLite
syncProducts()   →  limpa SQLite  →  busca API  →  popula SQLite  →  isLocal = false para todos
```

### Estado reativo (`ProductState`)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `status` | `ProductStatus` | `initial` / `loading` / `success` / `error` |
| `products` | `List<Product>` | Lista completa de produtos |
| `errorMessage` | `String?` | Mensagem de erro quando `status == error` |
| `showOnlyFavorites` | `bool` | Controla o filtro de favoritos |
| `visibleProducts` *(getter)* | `List<Product>` | Lista filtrada |
| `favoriteCount` *(getter)* | `int` | Total de produtos favoritados |

---

## 🔄 Migração: FakeStore API → DummyJSON

| Aspecto | FakeStore API | DummyJSON |
|---------|--------------|-----------|
| URL base | `https://fakestoreapi.com/products` | `https://dummyjson.com/products` |
| Campo imagem | `image` | `thumbnail` |
| Rating | `rating.rate` + `rating.count` | `rating` (direto) |
| Estoque | *(não existia)* | `stock` |
| Formato lista | Array `[...]` | Objeto `{ "products": [...] }` |
| Autenticação | Não suportada | `/auth/login` com JWT |

---

## 📦 Dependências

```yaml
dependencies:
  http: ^1.2.0                # Requisições HTTP
  shared_preferences: ^2.3.2  # Persistência do token de sessão
  sqflite: ^2.3.3+1           # Banco de dados SQLite local (mobile/desktop)
  path: ^1.9.0                # Utilitário de caminhos para o banco
```

---

## ▶️ Como executar

```bash
# 1. Instale as dependências
flutter pub get

# 2. Execute o app
flutter run
```

**Credenciais de teste (DummyJSON):**

```
Usuário: emilys
Senha:   emilyspass
```

> **Nota sobre o banco SQLite:** se você já tinha o app instalado de uma versão anterior, desinstale antes de rodar — o esquema do banco foi atualizado (novo arquivo `produtos_v3.db` com as colunas `thumbnail`, `rating` e `stock`).

---

## 📝 Questões para reflexão (Atividade)

As respostas estão no arquivo **`RESPOSTAS.md`** na raiz do projeto.

---

## 👨‍💻 Autor

Projeto desenvolvido como atividade da disciplina **Desenvolvimento para Dispositivos Móveis II**.