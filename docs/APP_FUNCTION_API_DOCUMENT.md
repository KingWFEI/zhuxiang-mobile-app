# 住享 App 功能与接口文档

## 1. 文档范围

本文档按当前 App 端代码已封装或已调用的接口整理，覆盖租户端、管家端门锁初始化、基础网络规范与页面功能。文档仅描述 App 现状，不包含后端管理端接口设计。

基础约定：

- App 名称：住享
- 当前开发环境 Base URL：`http://10.143.183.201:8000/api`
- 网络入口：`ApiClient`
- 认证方式：请求拦截器自动从本地读取 `accessToken`，请求头携带 `Authorization: Bearer <token>`
- 标准响应：多数接口按 `{ code, message, data }` 解析，`code = 200` 视为成功
- 金额单位：App 实体内部以“分”为主，部分租约接口兼容“元”并转换为“分”
- 时间格式：日期字段以 `yyyy-MM-dd` 或 ISO 时间字符串解析

## 2. 功能总览

| 模块 | 页面/入口 | 已实现功能 | 数据来源 |
| --- | --- | --- | --- |
| 登录注册 | `/login`、`/register` | 验证码登录、密码登录、注册、刷新 Token、退出登录 | 后端接口 |
| 首页 | `/tenant` | 首页聚合数据、服务入口、Banner/推荐位展示 | 后端接口 |
| 找房 | `/houses`、搜索/筛选/详情页 | 房源分页、关键词搜索、筛选排序、房源详情、已出租拦截 | 后端接口 + 本地热门小区 Mock |
| 租房流程 | `/rental-flow/...` | 创建租赁订单、实名、合同预览、确认合同、支付、线上签约、入住完成 | 后端接口 |
| 我的租约 | `/leases`、`/leases/:leaseId` | 租约列表、租约详情、电子合同、续租/退租旧动作 | 后端接口，失败可回退 Mock |
| 退租申请 | `/leases/:leaseId/termination/apply` | 查询当前退租申请、照片上传、提交退租申请、防重复进入 | 后端接口 |
| 报修服务 | `/repairs` | 当前房源报修、报修记录、详情、取消、评价 | 后端接口，失败可回退 Mock |
| 智能门锁 | `/tenant/leases/:leaseId/lock`、`/locks/records` | 租客开锁数据、权限概览、开锁记录 | 后端接口，记录页失败可回退 Mock |
| 我的 | `/profile`、编辑页、设置页 | 当前住房、门锁卡片、设置密码、改密码、换手机号、退出 | 后端接口 |
| 消息 | `/messages` | 消息分类和列表展示 | 本地 Mock |
| 管家端门锁 | `/staff/locks/init`、`/staff/locks/init/manage` | 门锁本地初始化、绑定房源、同步平台、状态上传、恢复出厂、开锁数据 | 后端接口 |
| 占位功能 | 账单、普通智能门锁入口、客服管家、预约看房、实名认证 | 已有路由和占位页 | 暂无真实接口 |

## 3. 基础网络与鉴权

### 3.1 ApiClient

| 项 | 说明 |
| --- | --- |
| 调用类 | `lib/core/network/api_client.dart` |
| 支持方法 | `GET`、`POST`、`PUT`、`DELETE` |
| 超时 | 连接 15 秒，响应 15 秒 |
| Base URL | 来自 `AppConfig.baseUrl` |
| 错误映射 | 401、5xx、超时、网络连接错误统一转为 `ApiException` |

### 3.2 请求拦截

| 能力 | 说明 |
| --- | --- |
| Token 注入 | 从本地 `StorageService.tokenStorage.readAccessToken()` 读取 Token |
| 请求头 | `Authorization: Bearer <accessToken>` |
| 日志 | 打印请求方法、URL、HTTP 状态 |
| 401 | 当前仅记录日志，刷新 Token 由认证流程处理 |

## 4. 接口清单

### 4.1 登录注册

调用位置：`lib/features/auth/data/auth_service.dart`

| 方法 | 路径 | App 功能 | 请求参数 | 成功数据 |
| --- | --- | --- | --- | --- |
| POST | `/auth/sms-code` | 发送验证码 | `phone`、`scene` | `expiresIn` |
| POST | `/auth/login/code` | 验证码登录/注册 | `phone`、`code` | `accessToken`、`refreshToken`、`expiresIn`、`user` |
| POST | `/auth/login/password` | 密码登录 | `phone`、`password` | 同登录结果 |
| POST | `/auth/register` | 注册账号 | `phone`、`code`、`password`、`nickname` | 同登录结果 |
| POST | `/auth/refresh` | 刷新 Token | `refreshToken` | `accessToken`、`refreshToken`、`expiresIn` |
| POST | `/auth/logout` | 退出登录 | `refreshToken` | `boolean` |

实现功能：

- 登录页支持验证码登录和密码登录。
- 注册页完成手机号、验证码、密码、昵称注册。
- 登录成功后保存 Token 和用户信息，路由守卫按角色进入租户端或管家端。
- 设置页调用退出登录并清理本地会话。

### 4.2 首页

调用位置：`lib/features/home/data/services/home_service.dart`

| 方法 | 路径 | App 功能 | 请求参数 | 成功数据 |
| --- | --- | --- | --- | --- |
| GET | `/home/data` | 首页聚合数据 | 无 | `HomeData` |

实现功能：

- 首页加载 Banner、推荐房源、服务入口等聚合数据。
- 服务入口跳转到租约、报修、门锁记录、客服等页面。
- 接口失败时页面按现有状态展示加载失败或空态。

### 4.3 找房与房源详情

调用位置：`lib/features/house/data/services/house_service.dart`

| 方法 | 路径 | App 功能 | 请求参数 | 成功数据 |
| --- | --- | --- | --- | --- |
| GET | `/houses` | 房源分页搜索 | `page`、`pageSize`、关键词、筛选、排序等查询参数 | `{ items, page, pageSize, total, hasMore }` |
| GET | `/houses/{houseId}` | 房源详情 | `houseId` | `HouseDetail` |

实现功能：

- 找房页分页加载可租房源，App 端会过滤 `isRented = true` 的房源。
- 搜索页支持关键词搜索、历史搜索、本地热门小区展示。
- 结果页支持筛选、排序、下拉刷新、加载更多。
- 详情页展示房源图片、价格、户型、标签、配套信息，并对已出租房源做提示拦截。

### 4.4 租房流程

调用位置：`lib/features/rental_flow/data/services/rental_flow_service.dart`

| 方法 | 路径 | App 功能 | 请求参数 | 成功数据 |
| --- | --- | --- | --- | --- |
| POST | `/rent-orders` | 创建租赁订单 | `houseId`、`startDate`、`leaseMonths`、`paymentMethod`、`tenantCount` | `RentOrder` |
| GET | `/rent-orders/{orderId}` | 查询订单详情 | `orderId` | `RentOrder` |
| GET | `/rent-orders/my` | 我的租房订单 | 无 | 订单列表 |
| POST | `/rent-orders/{orderId}/cancel` | 取消订单 | `orderId` | `RentOrder` |
| POST | `/rent-orders/{orderId}/hide` | 隐藏订单 | `orderId` | 空 |
| POST | `/rent-orders/{orderId}/real-name` | 提交实名信息 | 实名模型 `RealNameModel` | `RentOrder` |
| POST | `/files/upload` | 上传身份证图片 | `multipart/form-data`：`bizType`、`file` | `url`、`fileId` |
| GET | `/rent-orders/{orderId}/contract-preview` | 合同预览 | `orderId` | `ContractPreview` |
| POST | `/rent-orders/{orderId}/confirm-contract` | 确认合同 | `orderId` | `RentOrder` |
| GET | `/rent-orders/{orderId}/payment-info` | 获取支付信息 | `orderId` | `PaymentInfo` |
| POST | `/rent-orders/{orderId}/pay` | 提交支付 | `paymentMethod`、固定 `paymentChannel=mock` | 支付后重新查询订单 |
| POST | `/rent-orders/{orderId}/sign` | 在线签约 | `orderId` | `RentOrder` |

实现功能：

- 从房源详情进入租房流程，按“看房/申请/实名/合同/支付/签约/入住完成”页面推进。
- 订单状态在各步骤后刷新并缓存到服务层内存。
- 实名页面上传证件照后，将文件 URL 和实名信息提交到订单。
- 支付当前使用 `paymentChannel=mock`，由后端返回或更新订单状态。

### 4.5 我的租约与电子合同

调用位置：`lib/features/lease/data/services/lease_service.dart`

| 方法 | 路径 | App 功能 | 请求参数 | 成功数据 |
| --- | --- | --- | --- | --- |
| GET | `/leases/my` | 我的租约列表 | 无 | 租约列表 |
| GET | `/leases/{leaseId}/contract` | 查看电子合同 | `leaseId` | `LeaseContractDocument` |
| POST | `/leases/{leaseId}/renew` | 续租申请旧动作 | `leaseId` | 空 |
| POST | `/leases/{leaseId}/checkout` | 退租旧动作 | `leaseId` | 空 |

实现功能：

- 我的租约页展示当前租约和历史租约。
- 租约详情从列表数据中匹配当前 `leaseId`，展示房源、租金、押金、账单、门锁、管家等信息。
- 电子合同页通过租约 ID 拉取合同详情，支持合同正文、合同条款、签署时间、合同文件 URL 等字段。
- 租约接口失败时允许使用 Mock 租约数据回退，便于开发调试。

注意：

- 当前退租申请新流程使用 `contractId`，因此 `/leases/my` 返回的租约数据必须包含 `contractId`。
- 若租约已终止，后端应从当前有效租约列表中剔除，或返回明确状态供 App 展示历史租约。

### 4.6 退租申请

调用位置：

- `lib/features/lease/data/services/lease_service.dart`
- `lib/features/lease/domain/entities/lease_termination.dart`
- `lib/features/lease/presentation/pages/lease_termination_apply_page.dart`

| 方法 | 路径 | App 功能 | 请求参数 | 成功数据 |
| --- | --- | --- | --- | --- |
| GET | `/app/contracts/{contractId}/termination/current` | 查询当前合同是否已有退租申请 | `contractId` | `LeaseTerminationApplication` 或 `null` |
| POST | `/files/upload` | 上传退租补充材料照片 | `multipart/form-data`：`bizType=lease_termination`、`file` | `url`、`type`、`name` |
| POST | `/app/contracts/{contractId}/termination/apply` | 提交退租申请 | `LeaseTerminationRequest` | `id`、`applicationNo`、`status`、`statusText` |

退租申请请求体：

```json
{
  "reason": "工作变动",
  "expectedMoveOutDate": "2026-07-15",
  "hasMovedOut": false,
  "contactName": "张三",
  "contactPhone": "13800138000",
  "remark": "希望周末验房",
  "attachments": [
    {
      "url": "https://example.com/file.jpg",
      "type": "image",
      "name": "meter.jpg"
    }
  ]
}
```

实现功能：

- 从租约详情进入退租申请页前，按租约中的 `contractId` 查询当前退租申请。
- 若已存在退租申请，App 提示当前状态并阻止重复进入提交页。
- 申请页支持选择退租原因、预计搬离日期、是否已搬离、联系人、联系电话、备注。
- 补充材料使用真实照片上传接口，上传成功后把后端返回的 URL 放入申请请求体。
- 提交成功后展示申请编号和状态，并返回租约详情页。

后端配合点：

- 一个用户同一个合同/房源，在未完结退租流程内只能存在一条退租申请。
- `current` 接口需返回进行中的申请；无申请时返回 `data = null`。
- 提交接口若重复申请，应返回明确业务错误文案，App 会展示后端 `message`。

### 4.7 报修服务

调用位置：`lib/features/repair/data/services/repair_service.dart`

| 方法 | 路径 | App 功能 | 请求参数 | 成功数据 |
| --- | --- | --- | --- | --- |
| GET | `/repairs/my` | 我的报修列表 | 无 | 报修列表 |
| GET | `/leases/my` | 获取当前报修房源 | 无 | 租约/房源数据 |
| GET | `/repairs/{repairId}` | 报修详情 | `repairId` | `RepairOrder` |
| POST | `/repairs` | 创建报修 | `houseId`、`houseName`、`roomName`、`repairType`、`description`、`imageUrls`、`contactName`、`contactPhone`、`expectedVisitTime` | `RepairOrder` |
| POST | `/repairs/{repairId}/review` | 报修评价 | `rating`、`reviewContent` | `RepairOrder` |
| POST | `/repairs/{repairId}/cancel` | 取消报修 | `repairId` | `RepairOrder` |

实现功能：

- 报修首页展示当前住房和报修类型入口。
- 创建报修页支持水电、电路、家电、门锁、家具、网络、其他问题类型。
- 报修记录页支持全部、待受理、处理中、待评价、已完成、已取消筛选。
- 报修详情页展示状态、时间线、维修人员、评价入口和取消入口。
- 接口失败时允许回退 Mock 报修数据。

### 4.8 租客智能门锁

调用位置：

- `lib/features/lock/data/repositories/tenant_lock_repository.dart`
- `lib/features/lock/data/services/lock_record_service.dart`

| 方法 | 路径 | App 功能 | 请求参数 | 成功数据 |
| --- | --- | --- | --- | --- |
| GET | `/leases/{leaseId}/lock/unlock-data` | 获取当前租约门锁开锁数据 | `leaseId` | `TenantLockUnlockData` |
| GET | `/locks/my-permissions` | 获取我的门锁权限 | 无 | 当前门锁权限信息 |
| GET | `/locks/unlock-records/my` | 获取我的开锁记录 | 无 | 开锁记录列表 |

实现功能：

- 租客门锁页按租约 ID 获取 eKey/蓝牙开锁所需数据。
- 开锁记录页展示当前门锁权限、支持开锁方式、最近开锁时间和历史记录。
- 开锁记录接口失败时允许回退 Mock 数据。

### 4.9 我的与账号安全

调用位置：`lib/features/profile/data/services/profile_service.dart`

| 方法 | 路径 | App 功能 | 请求参数 | 成功数据 |
| --- | --- | --- | --- | --- |
| GET | `/profile/current-home` | 我的当前住房卡片 | 无 | `CurrentHome` 或 `null` |
| GET | `/profile/lock` | 我的门锁卡片 | 无 | `LockInfo` 或 `null` |
| PUT | `/profile/password/set` | 首次设置密码 | `newPassword` | 空 |
| PUT | `/profile/password` | 修改密码 | `oldPassword`、`newPassword` | 空 |
| PUT | `/profile/phone` | 修改手机号 | `newPhone`、`code` | 更新后的用户信息 |

实现功能：

- 我的页展示登录用户、当前住房、门锁入口、租约、订单、报修、设置等菜单。
- 编辑资料页支持设置密码、修改密码、发送短信验证码后修改手机号。
- 当前住房和门锁信息分开请求，单个接口失败不影响另一个卡片展示。

### 4.10 管家端门锁初始化与管理

调用位置：

- `lib/features/staff/lock_initial/data/services/staff_house_service.dart`
- `lib/features/staff/lock_initial/data/services/lock_api_service.dart`

| 方法 | 路径 | App 功能 | 请求参数 | 成功数据 |
| --- | --- | --- | --- | --- |
| GET | `/admin/houses` | 管家端选择房源 | 无 | 房源列表 |
| POST | `/admin/locks/local-initialized` | 保存门锁本地初始化数据 | `lockName`、`lockMac`、`lockData`、`rssi`、`battery` | `smartLockId`、门锁状态 |
| POST | `/admin/locks/{smartLockId}/bind-room` | 绑定门锁到房源/房间 | `houseId`、可选 `roomId` | 绑定结果 |
| POST | `/admin/locks/{smartLockId}/sync-platform` | 同步门锁到开放平台 | `smartLockId` | `lockId`、`keyId`、状态 |
| DELETE | `/admin/locks/{smartLockId}/bind-room` | 同步失败时回滚绑定 | `smartLockId` | 解绑结果 |
| GET | `/admin/locks/by-mac` | 按 MAC 查询门锁 | `lockMac` | 门锁记录或 `null` |
| GET | `/admin/locks/{smartLockId}/detail` | 门锁管理详情 | `smartLockId` | 门锁详情 |
| POST | `/admin/locks/{smartLockId}/ble-status` | 上传蓝牙状态 | `battery`、`rssi` | 空 |
| POST | `/admin/locks/{smartLockId}/mark-reset` | 标记恢复出厂 | `smartLockId` | 空 |
| GET | `/admin/locks/{smartLockId}/unlock-data` | 获取管家端开锁数据 | `smartLockId` | `UnlockDataResponse` |

实现功能：

- 管家角色登录后进入管家端底部 Tab。
- 门锁初始化页完成蓝牙扫描、本地初始化、选择房源、绑定、同步平台的流程。
- 同步平台失败时可调用解绑接口回滚。
- 门锁管理页展示门锁详情、上传蓝牙信号/电量、恢复出厂标记、获取开锁数据。

## 5. 页面与路由

| 路由 | 页面 | 功能状态 |
| --- | --- | --- |
| `/` | 启动页 | 已实现 |
| `/login` | 登录页 | 已实现 |
| `/register` | 注册页 | 已实现 |
| `/tenant` | 租户首页 | 已实现 |
| `/houses` | 找房页 | 已实现 |
| `/houses/:houseId` | 房源详情 | 已实现 |
| `/house-search` | 搜索页 | 已实现 |
| `/house-search-result` | 搜索结果 | 已实现 |
| `/house-filter` | 筛选页 | 已实现 |
| `/rent-orders` | 我的租房订单 | 已实现 |
| `/rental-flow/:houseId/...` | 租房流程 | 已实现 |
| `/leases` | 我的租约 | 已实现 |
| `/leases/:leaseId` | 租约详情 | 已实现 |
| `/leases/:leaseId/contract` | 电子合同 | 已实现 |
| `/leases/:leaseId/termination/apply` | 退租申请 | 已实现 |
| `/repairs` | 报修首页 | 已实现 |
| `/repairs/create` | 创建报修 | 已实现 |
| `/repairs/records` | 报修记录 | 已实现 |
| `/repairs/:repairId` | 报修详情 | 已实现 |
| `/tenant/leases/:leaseId/lock` | 租客门锁开锁 | 已实现 |
| `/locks/records` | 开锁记录 | 已实现 |
| `/profile` | 我的 | 已实现 |
| `/profile/edit` | 编辑资料 | 已实现 |
| `/profile/settings` | 设置 | 已实现 |
| `/messages` | 消息中心 | 本地 Mock |
| `/bill` | 账单 | 占位 |
| `/lock` | 智能门锁普通入口 | 占位 |
| `/customer-service` | 客服管家 | 占位 |
| `/appointment` | 预约看房旧入口 | 占位 |
| `/real-name-auth` | 实名认证旧入口 | 占位 |
| `/staff` | 管家工作台 | 已实现 |
| `/staff/locks/init` | 管家门锁配置 | 已实现 |
| `/staff/locks/init/manage` | 管家门锁管理 | 已实现 |
| `/staff/debug` | 系统调试 | 占位 |

## 6. 当前实现边界

- 房源热门小区仍使用本地 Mock，真实接口未接入。
- 消息中心使用本地 Mock，未发现消息接口封装。
- 账单、普通智能门锁入口、客服管家、旧预约看房、旧实名认证仍为占位页。
- 租约、报修、开锁记录服务开启了 Mock fallback，开发时接口异常可能不会直接暴露为空白页。
- 退租新流程依赖后端在 `/leases/my` 中返回 `contractId`；没有 `contractId` 时 App 无法提交退租申请。
- 退租重复申请的最终一致性必须由后端保证，App 只做进入前查询和提交失败提示。

