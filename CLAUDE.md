# Java 领域驱动设计（DDD）面试项目开发约定

## 目标与技术栈

- 以 AI 工程协作为开发方式，交付可运行、可验证、职责清晰的 Web 后端。
- 使用 Spring Boot、MyBatis、Lombok、MapStruct；默认 Maven 单模块。
- 已有项目读取并沿用 JDK、Spring Boot 和数据库配置。新项目使用 ddd-java 创建脚本，自动查询最新稳定版 Spring Boot 并匹配依赖，不再询问 Spring 版本；记录实际版本。
- 数据访问使用 MyBatis。其他组件仅在题目需求需要时增加，并说明用途。
- 实际领域、接口和业务规则（Business Rule）以面试题为准。

## 术语说明

- 领域驱动设计（Domain-Driven Design，DDD）：围绕业务概念和规则设计软件模型。
- 实体（Entity）：通过身份持续区分和跟踪的业务对象，属性变化后仍是同一个对象。
- 值对象（Value Object）：通过属性值表达业务含义的对象，通常设计为不可变。
- 聚合（Aggregate）：共同维护一组一致性规则的领域对象整体，可以包含一个或多个对象。
- 聚合根（Aggregate Root）：聚合的对外操作入口，自身也是实体，负责维护聚合的整体规则。
- 聚合边界（Aggregate Boundary）：确定哪些对象属于同一聚合、哪些规则需要在其内部一起保证。
- 不变量（Invariant）：业务操作完成后必须始终成立的规则。
- 领域模型（Domain Model）：表达业务概念、状态、行为及规则的模型。
- 统一语言（Ubiquitous Language）：需求讨论、模型命名和代码共同使用的业务术语。
- 应用服务（Application Service）：本项目的 Service，负责组织业务用例的执行步骤。
- 数据存取组件（Repository）：定义领域对象的读取和保存操作，实现中组合 Mapper 和 Converter。
- 数据传输对象（Data Transfer Object，DTO）：用于传递 API 请求和响应数据。
- 数据库映射对象（Persistence Object，PO）：用于承接 MyBatis 查询结果及写入数据，与领域模型分开。

## 工作流程与人工验收（包括 Superpowers）

1. 先澄清核心用例、业务规则、异常和验收条件，再列领域模型、聚合、不变量、API 与表结构。
2. Task 按 user story/业务用例划分，名称表达业务目标（例如“用户预约会议室”）。同一个 Task 内分小步编码：一个 Controller → review/accept → Service → review/accept → 所需 Domain 与持久化等，每步单独验收；技术层不是独立 Task。先确认 story 计划及内部步骤。
3. 一次仅实现一个获批编码步骤。完成后列出新增/修改/删除文件、关键差异、实际检查结果和下一步，结束本轮，等待用户 review。包括尚未 git add 的新文件。
4. 用户明确 accept 当前版本后才开始下一项；提出修改意见则仅修当前项，重新 review。accept 不代表允许完成整个需求，也不代表允许 commit。跨层未完成导致暂时无法编译时说明，不偷偷补齐下一层。
5. 当前 story 的实现全部验收后再写测试用例；测试文件与场景也先交用户 review，accept 后才运行。不得强制 TDD 或提前执行测试步骤。
6. 测试失败先说明修复范围；修改已验收代码前取得同意，修复后重新 review，再获 accept 才重跑。未运行或失败的验证不能声称通过。
7. 约定测试通过后，列出提交文件、验证结果和 commit message，单独询问是否 commit。用户明确同意提交后才暂存对应改动并提交；不自动 push、merge、stash、reset，不混入用户原有修改。
8. Superpowers 的 task 清单必须包含上述人工停点，不得因其连续执行、TDD 或自动提交默认流程跳过验收。不得在说“请 review”后继续调用工具推进。

完整交接和授权语义见项目 `.claude/rules/ddd-review.md` 或 ddd-java 的 `references/review-workflow.md`。每步都要停，不以最终集中 review 代替。

## 需求迭代与变更

1. 修改前阅读相关实现和测试，列出新旧业务规则（Business Rule）的差异，以及必须保持不变的行为。
2. 分析受影响的领域模型（Domain Model）、Service、Repository、API、SQL、表结构和测试，给出最小修改方案；涉及关键业务或兼容性变化时先对齐方案。
3. 修改前检查 git status、相关测试代码与已有测试结果，保留已有改动。需要新增或运行基线测试时先作为独立编码步骤 取得同意；不得借“回归保护”跳过人工验收。区分原有失败与本次引入的问题。
4. 按用例分步修改，沿用现有架构、命名和代码风格；无关重构、全局格式化及依赖升级作为独立任务处理。
5. API 变更检查旧调用方兼容性；数据库变更检查已有数据能否读取、字段默认值、历史数据迁移及约束。主动变更旧行为时明确说明影响。
6. 验证新增需求与受影响的旧流程，覆盖正常、异常和边界场景；涉及并发时验证并发规则。被新需求替代的测试按新验收条件更新并说明原因。
7. 完成后检查 git diff，确认改动范围与需求一致；汇报变更内容、实际测试结果、兼容性变化及未解决问题。

## 架构与命名

采用轻量 DDD：Controller → Service → 领域模型（Domain Model） / Repository 接口。
RepositoryImpl 实现 Repository，内部组合 MyBatis Mapper 和持久化 Converter。

- 应用服务接口命名为 XxxService，实现类命名为 XxxServiceImpl。
- Service 是应用层编排者；业务状态变化和核心校验优先由领域模型（Domain Model）承担。
- 跨模型流程由 Service 协调；可独立表达的业务规则（Business Rule）优先建模为有明确含义的对象或策略。
- 按业务职责和当前用例划分 Service、领域模型（Domain Model）与 Repository。
- Repository 围绕聚合（Aggregate）设计，一个 Repository 可以组合多个 Mapper。
- Service 和 Repository 均保留接口与实现：XxxService / impl/XxxServiceImpl、repository/XxxRepository / infrastructure/repository/XxxRepositoryImpl。调用方注入接口。

## 推荐代码结构

采用按层分包。先按通用框架组织，再根据实际业务命名类；只创建当前用例需要的文件。

### 项目根目录

```text
project/
├── pom.xml             # Maven 依赖与构建配置
├── Dockerfile          # 应用镜像构建规则
├── .dockerignore       # 排除无关构建文件
├── docker-compose.yml  # 本地应用与 MySQL 编排
├── README.md           # 项目说明、启动与验证步骤
├── CLAUDE.md           # AI 开发约定
└── src/
    ├── main/
    │   ├── java/       # 下述通用框架与业务代码
    │   └── resources/  # 应用配置、SQL XML 与初始化资源
    └── test/java/      # 测试代码
```

### 通用框架

```text
src/main/java/com/example/project/
├── controller/          # 接收请求、调用 Service 接口
├── service/             # 业务用例接口
│   └── impl/            # 编排领域模型（Domain Model）、调用 Repository、管理事务
├── repository/          # 定义领域对象的读取、保存接口
├── infrastructure/
│   ├── repository/      # RepositoryImpl，组合 Mapper 与持久化 Converter
│   ├── mapper/          # MyBatis 接口
│   ├── po/              # 数据库映射对象
│   └── converter/       # XxxPersistenceConverter
├── domain/              # 直接放聚合根（Aggregate Root）、实体（Entity）、值对象（Value Object）和业务枚举
├── converter/           # XxxApiConverter，API 转换
├── dto/
│   ├── request/         # API 入参
│   └── response/        # API 出参
├── exception/           # 异常定义和统一异常处理
└── config/              # 配置类

src/main/resources/
└── mapper/              # MyBatis SQL XML

src/test/java/com/example/project/
```

### 职责与依赖

- 新项目使用上述单模块 infrastructure 分包结构；已有项目先检查实际目录，不自动迁移、搬文件或混用两套结构。迁移需单独计划并获用户同意。
- Service 承担应用层职责；领域类直接放在 domain 下。
- Controller 注入 Service 接口，不直接调用 Mapper 或 Repository；不直接把领域对象、PO 序列化为 API 响应。
- ServiceImpl 编排领域模型（Domain Model），注入 Repository 接口，不依赖 Mapper、PO 或 RepositoryImpl。
- RepositoryImpl 封装 Mapper 和持久化 Converter，接口使用领域类型，不暴露 SQL 或 PO。
- 为简化实现，Service 可接收请求 DTO、返回响应 DTO，或使用明确参数；通过 API Converter 完成必要转换。
- API 数据传输对象放在 dto/request 和 dto/response 下，业务模型放在 domain 下。
- 查询时由 Repository 调用 Mapper 获取 PO，经 Converter 转为领域对象，再转换为 Response；创建时由 Service 调用 create() 或构造方法创建领域对象，再由 Repository 转 PO 保存。
- domain 不依赖 Spring、MyBatis、DTO、PO、Mapper、Service 或 Repository 实现。
- BusinessException 保持框架无关；领域模型（Domain Model）不得依赖 GlobalExceptionHandler 等 Web 异常处理组件。
- Service、Repository 接口不加 Spring 组件注解；ServiceImpl 加 @Service，RepositoryImpl 加 @Repository，使用构造器注入。
- Mapper 通过 @Mapper 或 @MapperScan 注册；MapStruct Converter 使用 Spring 组件方式生成实现。

## DDD 建模规则

1. 根据业务用例和规则识别模型，模型名称与需求中的业务术语保持一致，形成统一语言（Ubiquitous Language）。
2. 需要通过身份持续跟踪的对象建为实体（Entity）；由属性值表达含义的概念建为值对象（Value Object）。
3. 根据需要共同保证的不变量（Invariant）划分聚合（Aggregate），明确聚合根（Aggregate Root）及内部对象。
4. 将业务行为分配给负责该规则的模型；Service 负责加载、调用和保存。
5. 根据业务含义、生命周期和一致性要求确定对象关系，而不是直接照搬数据库表关系。
6. 建模结果列出：模型名称、职责、关键属性、业务方法、所属聚合（Aggregate）及核心规则。

## 领域模型（Domain Model）实现

- 实体（Entity）有身份和业务行为；值对象（Value Object）按值表达含义，优先不可变。
- 聚合根（Aggregate Root）自身也是领域实体（Entity），可以持有聚合（Aggregate）内部的实体（Entity）和值对象（Value Object）；这些对象仍定义为独立类。
- 对聚合（Aggregate）内部对象的业务修改通过聚合根（Aggregate Root）入口进行，不暴露可任意修改的内部集合或公共 setter。
- 状态转换条件由模型的业务方法校验，字段取值规则由构造方法或相应行为方法校验。
- 创建领域对象使用 create() 或构造方法，负责新建时的业务校验和初始化；查询得到的 PO 通过 Converter 转成领域对象。
- Lombok 可用于 DTO/PO 和构造器注入；领域实体（Entity）避免 @Data 带来的公开 setter 及不合适的 equals/hashCode。

## Repository 与 MyBatis

- Repository 接口使用领域类型和普通 Java 类型，不暴露 PO、Mapper、MyBatis 分页类型或 SQL 细节。
- RepositoryImpl 负责查询记录、组合聚合（Aggregate）、转换对象以及保存聚合（Aggregate），不承担业务状态判断。
- 所有 MyBatis SQL（包括简单 CRUD、复杂查询和动态 SQL）统一写在 src/main/resources/mapper/ 下的 Mapper XML 中。
- Mapper 接口仅声明数据访问方法；禁止使用 @Select、@Insert、@Update、@Delete 及对应的 SQL Provider 注解编写 SQL。@Mapper 和 @Param 可正常使用。
- XML 文件按 XxxMapper.xml 命名，namespace 对应 Mapper 接口全限定名，statement id 对应接口方法名；多参数通过 @Param 明确命名。
- 配置 Mapper XML 的扫描路径；字段与 PO 属性不一致时，使用 resultMap 或明确的列别名完成映射。
- 查询参数使用 #{...} 绑定；动态排序字段和方向通过 XML 条件分支或固定白名单控制，避免直接拼接用户输入。
- findById 明确不存在语义，优先返回 Optional；Service 处理不存在情况。
- 明确新增与更新的保存语义，不假定 MyBatis 有脏检查或自动保存行为。
- 保存包含明细的聚合（Aggregate）时，明确明细新增、修改和删除策略，保证根与明细在同一事务中提交。
- 事务通常放在 ServiceImpl 的公开用例方法上，用 @Transactional 管理一个业务操作的原子性。
- 若需求涉及并发修改，使用版本条件更新并检查影响行数；事务本身不能避免丢失更新。
- 列表查询按需使用分页投影，不为返回摘要而加载每条记录的完整聚合（Aggregate）；不得通过查询投影绕过写入规则。

## MapStruct 与 Converter

- Converter 是转换组件的命名，MapStruct 负责生成字段映射实现；不重复手写同一套映射。
- MyBatis 接口命名 XxxMapper，MapStruct 接口命名 XxxConverter，避免混淆。
- XxxApiConverter 处理 API DTO 与领域对象之间需要的字段映射，尤其是领域对象 → 响应 DTO；新建对象的状态由 create() 或构造方法初始化。
- XxxPersistenceConverter 处理 Domain ↔ PO；RepositoryImpl 调用它。
- 使用 Spring 组件方式注入 MapStruct Converter；配置注解处理器并实际编译验证 Lombok 与 MapStruct 的配合。
- PO 转领域对象时，由 Converter 映射已有字段；MapStruct 可使用匹配的构造方法完成映射。
- Converter 只做结构转换，不查询数据库、不计算业务价格、不决定业务状态。

## API、验证与交付

- Controller 使用 Bean Validation 校验输入格式；领域模型（Domain Model）仍需维护自身业务规则（Business Rule）。
- 统一异常处理，区分参数错误、资源不存在、业务冲突和系统异常；不向客户端泄露内部堆栈。
- 数据库变更采用项目已有迁移机制；无机制时提供可重复使用的初始化脚本和启动说明。
- 单元测试覆盖领域规则及边界、ServiceImpl 的用例编排，Service 测试可 Mock Repository；仅声明方法的接口不单独重复测试。
- RepositoryImpl 使用测试数据库验证真实 SQL、转换与聚合（Aggregate）保存；通过 Spring 集成测试验证事务，并完成至少一个 API 端到端验证。
- 不用纯 Mock 测试证明 SQL 正确；使用 H2 时明确它不能完全证明目标数据库兼容性。
- 采用项目已有构建命令；存在 Maven Wrapper 时使用 ./mvnw test、./mvnw verify；没有时使用已安装的 Maven，不编造可执行命令。
- 新项目由创建脚本生成 Dockerfile、.dockerignore、docker-compose.yml 和 Swagger UI 依赖。README 按当前项目交付要求编写并纳入待验收编码步骤，支持通过 Docker 启动；README 说明构建、运行及环境变量配置。
- Docker 镜像构建和本地容器启动作为验证计划的独立步骤，用户验收相关配置并同意运行后执行；环境无法运行 Docker 时标记未验证。生成配置不代表授权部署。
- 不写入真实密钥，不擅自修改无关代码，不用删除测试或吞掉异常来获得通过结果。
