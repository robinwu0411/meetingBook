---
name: ddd-java
description: 为 Java Spring Boot、MyBatis XML、MapStruct 项目进行轻量 DDD 领域建模、设计与审查。也可通过附带脚本创建单模块项目。用于从新需求或需求变更识别实体、值对象、聚合、不变量、业务方法，映射 API、数据库和持久化。沿用单模块 controller/service/domain/repository/infrastructure 结构，不负责部署，不强制 TDD。
---

# Java DDD 领域建模

## 必须执行的人工验收流程

开始任何开发任务前读取 references/review-workflow.md，并严格执行。计划确认 → 当前 user story 内的一个小步编码 → 列出本次修改文件和差异 → **结束本轮等待用户 accept** → 下一项。当前 story 的实现全部验收后才写测试；测试用例也要先 review，再运行。测试通过后单独询问是否 commit，明确获准才提交。不得把用户一次 accept 当成后续步骤或提交的授权。

Superpowers 的 Task 必须按 user story 划分，并把这些停点写进各 Task 内部的执行步骤，不能仅放在总结里；不能自行标记用户已验收。API、Domain、Service、Infrastructure 可分步审查，跨层依赖必须在计划中说明。

新项目脚本自动安装项目 review 规则和 Git 操作 ask 权限。已有项目安装：`python3 <本技能目录>/scripts/install-review-controls.py <项目根目录>`。安装前说明会新增 `.claude/rules/ddd-review.md` 并合并 `.claude/settings.local.json`；不改用户其他设置。配置的作用与局限见 references/claude-review-setup.md。

## 创建项目

仅当用户要求创建新项目时，运行本技能目录内的 scripts/create-ddd-project.sh；已有项目建模、实现或修改时不得运行。

命令：bash <本技能目录>/scripts/create-ddd-project.sh <新项目目录> <Java根包>

例如：bash ~/.claude/skills/ddd-java/scripts/create-ddd-project.sh ~/projects/meeting-room com.example.meetingroom

- 用户说“帮我创建项目”时，先在对话中问“项目路径是什么？默认使用当前目录”。用户说“当前路径”就使用当前工作目录，不额外创建同名子目录。
- 接着只询问 Java 根包，默认 com.example.demo；已经提供的参数不要重复问。不询问 Spring Boot 版本。收集完成后用参数模式执行脚本，避免后台工具卡在 stdin 等待。
- 用户在自己的终端直接运行脚本且不传参数时，脚本交互询问路径和包名两项，路径回车默认当前目录。
- 当前目录必须为空，或只包含 .git、.gitignore、.claude、CLAUDE.md、.DS_Store；保留已有规则及 skill。存在业务代码或其他文件时停止，不覆盖。目录名须符合小写字母开头、数字和连字符的项目命名规则。
- 脚本需要 Python 3 和 Git；生成后的编译运行需要 JDK 17+、Maven 和配置好的 MySQL。
- 创建时联网从 Maven Central 查询最新正式版 Spring Boot（排除预览版和 SNAPSHOT），自动匹配 Boot 3/4 对应的 MyBatis starter 主版本及 springdoc（Boot 3 → springdoc 2，Boot 4 → springdoc 3），并记录实际版本。查询失败或出现未支持的 Boot 主版本时停止，不静默使用旧版本。
- 生成本技能约定的单模块 infrastructure 结构及 MyBatis XML、MapStruct、Lombok 配置，同时生成 Swagger UI 依赖、Dockerfile、.dockerignore、docker-compose.yml（应用 + MySQL，健康检查和数据卷），供本地开发使用；不自动启动容器或部署。
- 脚本会把本技能的 SKILL.md、references、scripts 复制到新项目 .claude/skills/ddd-java。
- 优先复制执行命令时当前工作目录的 CLAUDE.md 到项目根目录，其次使用技能附带的 CLAUDE.md。目标已有 CLAUDE.md 时保留；源和目标相同时无需复制。缺少时明确提醒用户放入。
- 自动 git init -b main 创建独立本地 Git 仓库；已有 .git（含 worktree 文件）则保留，不暂存、提交或配置远程。不自动下载项目依赖或运行应用。报告实际执行结果，未编译不得声称编译通过。

## 工作边界

- 当前会话用户明确要求优先；读取项目 CLAUDE.md 和实际代码。若发现旧规则要求整用例连续实现、测试先行或自动提交，指出与当前逐步验收要求的冲突，按用户最新要求执行，不静默跳过 review。
- 本技能附带 CLAUDE.md 为新项目默认约定。创建脚本仍优先保留/复制用户自己的 CLAUDE.md，不静默覆盖；发现冲突时先给出修订建议。
- 新项目默认 infrastructure 结构；已有项目若使用 repository.impl、mapper、po、converter 的扁平结构，沿用现状并明确路径映射，不能为套 skill 自动迁移。
- 按项目交付要求将 README、数据库初始化资源、Swagger、Docker 配置与验证分别纳入编码步骤。编译检查跳过测试不等于最终测试通过；Docker 构建中的跳过测试也不算验证通过。

- 先读项目 CLAUDE.md、相关实现与测试，以用户要求、确认的业务规则和项目约定为准。
- 中文解释；首次出现的术语附英文；代码名称用英文。
- 用户只要求建模时，输出设计，不直接改代码。实现已获授权时，仍按当前获批编码步骤 推进，遵守逐步人工验收。
- 与 Superpowers 配合时，把本技能作为设计阶段的方法，不重复启动另一套澄清流程。
- 允许先实现后补测试，不强制 TDD，不得因测试顺序删除已有实现。
- 不引入多模块、Case 层、部署流程、Docker、微服务、CQRS 或事件系统，除非实际需求要求。

## 1. 从用例和规则开始

已有项目先读调用链、领域对象、Repository、XML 和测试，区分既有行为与新增需求。空项目从题目开始。

每个用例确认：参与者、目标、输入、前置条件、成功后的状态、失败后哪些数据不变、正常/失败/边界验收例子。按需求确认重复请求和并发语义。

列出已确认事实、假设与阻塞问题，只问影响行为、数据一致性和设计的问题。形成统一语言（Ubiquitous Language），不要根据表名机械生成模型，不凭示例添加支付、库存等未要求功能。

## 2. 识别对象

- 实体（Entity）：以身份持续追踪，属性变化仍是同一对象。
- 值对象（Value Object）：按值表达含义，优先不可变，有实际校验、运算或比较价值；不要包装每个基本类型。
- 数据传输对象（DTO）：API 输入输出，不承担业务状态变化。
- 持久化对象（PO）：MyBatis 数据载体，不决定业务规则。

给每个模型写一句职责，列身份、状态和生命周期。领域类数量不由数据库表数量决定。

## 3. 先不变量，再聚合边界

不变量（Invariant）是业务操作完成后必须成立的规则。先输出：

| 规则 | 涉及对象 | 是否必须立即一致 | 维护者 | 失败行为 |
|---|---|---|---|---|

据此划分聚合（Aggregate）和聚合根（Aggregate Root）：
- 聚合根自身是实体，控制内部状态变化；不强制创建额外的 Aggregate 包装类。
- 只把必须共同维护规则、生命周期紧密相关的对象纳入聚合，不按外键、页面或一次请求涉及的数据划分。
- 明确一个实体是独立聚合根还是聚合内部对象，在各用例中保持一致。
- 用户通常独立于订单；订单保存 userId 和必要快照。必须基于业务确认，不把用户、商品、库存全部塞进订单。
- 聚合之间优先按 ID 关联；应用服务可以分别加载独立聚合。
- 内部对象的修改通过聚合根完成，不泄露可任意修改的集合或对象引用。
- 只读查询可以使用投影，不要求加载完整聚合，但不能用投影绕过写入规则。
- 不把“一事务永远只能修改一个聚合”当硬规则。单库确需跨聚合原子操作时，说明理由，由应用服务管理事务；跨服务调用不能被本地事务自动回滚。

## 4. 为模型分配业务方法

先设计行为再补字段，输出：

| 模型 | 类型/聚合归属 | 关键状态 | 业务方法与参数 | 前置条件/规则 | 状态变化/失败 |
|---|---|---|---|---|---|

- 相关状态由负责它的模型维护，例如 order.cancel()、order.changeItemQuantity(itemId, quantity)。
- ServiceImpl 是应用服务（Application Service），负责加载、调用、保存和事务；业务状态判断不散落在 Controller、Service 和 Repository 中。
- 单个实体无法自然承担的纯业务规则，可放在有明确职责的领域策略或领域服务；不为每个实体生成 DomainService。
- 将外部数据获取和业务判断分离。领域对象不直接调 Mapper、HTTP 或 Spring 服务。
- 新建用 create() 或构造方法，校验并初始化。查询由 PO 经 Converter 恢复已有字段，保留 ID、状态、版本，不重复创建副作用，不强制 reconstitute 命名。
- 不为映射方便开放公共 setter 或使用会泄露修改入口的 Lombok @Data。
- 多种可替换算法才考虑策略；可复用或动态组合校验才考虑责任链；真实公共流程加变化点才考虑模板方法。几个 if 不足以要求设计模式。

## 5. 映射到项目结构

默认单 Maven 模块。保持现有根包，采用以下职责映射；若项目 CLAUDE.md 有明确新约定则以其为准。

| 包/资源位置 | 内容 |
|---|---|
| controller | HTTP 接口、输入验证、响应 |
| service、service.impl | XxxService、XxxServiceImpl，用例编排和事务 |
| domain | 聚合根、实体、值对象、业务枚举、必要的纯领域策略 |
| repository | XxxRepository 接口，属于领域契约 |
| infrastructure.repository | XxxRepositoryImpl |
| infrastructure.mapper | XxxMapper，MyBatis 数据访问接口 |
| infrastructure.po | 数据库映射对象 |
| infrastructure.converter | XxxPersistenceConverter，Domain 与 PO 转换 |
| converter | XxxApiConverter，API 对象转换 |
| dto.request、dto.response | 请求与响应 |
| exception、config | 通用异常和应用配置 |
| src/main/resources/mapper | XxxMapper.xml，所有 SQL |

依赖规则：
- Controller 调 Service 接口；ServiceImpl 调领域行为和 Repository 接口。
- Repository 接口只暴露领域/普通 Java 类型；RepositoryImpl 组合 Mapper 和持久化 Converter。
- domain 与 repository 接口不依赖 infrastructure、Spring、MyBatis、DTO 或 PO；保持业务异常框架无关。
- ServiceImpl 不依赖 infrastructure、Mapper、PO 或 RepositoryImpl。
- RepositoryImpl 负责加载、组装、转换和保存，不决定业务状态。
- ServiceImpl 使用 @Service 和用例级 @Transactional，RepositoryImpl 使用 @Repository，采用构造器注入。不在 domain 中复制带 Spring 注解的 Domain Service。
- 保留项目允许 Service 使用 DTO 的轻量约定，不自动新增 Command/Result/Case 全套层级。
- MapStruct 只做结构转换，不查询数据库、不计算业务规则、不决定新建状态。

## 6. 从模型落地 API 和表

先有用例与模型草案，再迭代 API 和 schema，不要求所有领域代码写完才考虑持久化。

- API 明确输入、输出、错误、权限前提和有需求时的幂等语义。
- 表明确主键、关联 ID、唯一约束、空值、必要索引和明细保存方式。模型和表不要求一一对应。
- Repository 按聚合/用例定义，不按每张表生成接口。
- 所有 SQL 放 Mapper XML；Mapper 接口不使用 SQL 注解；参数绑定，避免直接拼接输入。
- 查询：Mapper → PO → PersistenceConverter → 领域对象；保存反向执行，必须显式 save/update，MyBatis 不自动保存领域对象变化。
- 在 ServiceImpl 管理事务，说明根与明细的原子保存策略。
- 并发敏感规则选择版本条件/状态条件更新或必要锁，并检查影响行数；仅内存校验和 @Transactional 不足以解决竞争。
- 修改 schema 考虑历史数据和兼容性，不随意重建表。

## 7. 验证与迭代

用正常、失败、边界及相关并发场景走模型：
- 是否能通过领域方法完成用例，而不用外部偷偷 setStatus？
- 是否可绕过聚合根破坏规则？是否为读取方便错误合并聚合？
- 是否保留旧接口、历史数据及非目标行为？
- 领域单测、应用编排测试、真实 SQL/事务集成验证分别覆盖什么？

建模阶段只给验证计划，不声称测试通过；实现阶段报告实际执行结果。不强制测试先行；如需先补旧行为回归保护，应先纳入获批计划，不能跳过编码验收。保留用户已有改动，不自动 stash、reset、提交或合并。

## 输出

按任务规模简化，至少提供：
1. 用例、业务规则、未决问题。
2. 模型表：身份、职责、状态、方法、聚合归属。
3. 聚合边界及不变量的理由，不仅列类名。
4. 核心用例的加载 → 领域行为 → 保存步骤。
5. API、表、Repository/XML 对应关系及具体包路径。
6. 修改范围、验收例子和验证计划。

只按请求或已有约定写设计文件，不制造大量流程文档。需要具体示例时读 references/order-modeling.md。

## 参考边界

参考 xfg-ddd-skills 的业务与数据访问分离、复杂逻辑按职责拆分思路，独立编写本流程。不继承其强制目录、多模块、部署或 Spring Domain Service 约定。
来源：https://github.com/fuzhengwei/xfg-ddd-skills/blob/main/references/domain-design-guide.md
