# 订单建模示例

以下是演示假设，不是项目需求：仅待支付订单可取消或修改明细，明细数量为正，总额等于明细金额之和。

| 对象 | 归属 | 理由 |
|---|---|---|
| Order | 聚合根 | 维护订单状态及明细整体规则 |
| OrderItem | 内部实体 | 有明细身份，修改受订单状态约束 |
| Money | 按需引入的值对象 | 金额、币种、精度和运算 |
| User | 独立聚合根（若系统管理用户） | 用户生命周期独立于订单 |
| userId | 订单关联字段 | 无需把 User 装入订单聚合 |
| 商品名称、成交价 | 明细历史快照 | 不受后续商品改名、改价影响 |

领域方法：Order.create(userId, items)、order.cancel()、order.changeItemQuantity(itemId, quantity)。重复取消应幂等成功还是报错，需要确认。不提供任意 setStatus 或 setTotalAmount。

取消流程：service.impl.OrderServiceImpl 加载 Order，调用 cancel()，再调用 repository.OrderRepository.save(order)。事务在 ServiceImpl。infrastructure.repository.OrderRepositoryImpl 使用 infrastructure.mapper 下的 Mapper 和 XML 保存；如要防止支付与取消竞争，更新包含版本或原状态条件，检查影响行数并返回冲突。

Order 与 OrderItem 放 domain；OrderPO、OrderItemPO 放 infrastructure.po；OrderPersistenceConverter 放 infrastructure.converter。查询恢复必须保留 ID、状态和版本，不能调用会重置状态的新建工厂。API Converter 保留在 converter。

订单表和明细表不意味着两个聚合；用户表与订单表的外键也不意味着一个聚合。不额外创建只装 Order 的 OrderAggregate。

需求变为“已支付未发货可申请取消”时，先确认是直接取消还是申请，是否退款和异步处理，再修改状态规则、模型和 SQL；不要在 Controller 直接放宽状态校验，也不要自动添加未确认的退款系统。
