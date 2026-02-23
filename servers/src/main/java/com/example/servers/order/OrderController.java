package com.example.servers.order;

import com.example.servers.BaseResponse;
import com.example.servers.cart.Cart;
import com.example.servers.cart.CartItem;
import com.example.servers.cart.CartItemRepository;
import com.example.servers.cart.CartRepository;
import com.example.servers.coupon.Coupon;
import com.example.servers.coupon.CouponRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@RestController
public class OrderController {

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final CouponRepository couponRepository;

    public OrderController(OrderRepository orderRepository,
                           OrderItemRepository orderItemRepository,
                           CartRepository cartRepository,
                           CartItemRepository cartItemRepository,
                           CouponRepository couponRepository) {
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.cartRepository = cartRepository;
        this.cartItemRepository = cartItemRepository;
        this.couponRepository = couponRepository;
    }

    @PostMapping("/order/create")
    @Transactional
    public BaseResponse<Map<String, Object>> createOrder(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        
        // 获取用户购物车中已选中的商品
        Optional<Cart> cartOpt = cartRepository.findByUserId(userId);
        if (cartOpt.isEmpty()) {
            return new BaseResponse<>("400", "购物车为空", null);
        }
        
        Cart cart = cartOpt.get();
        List<CartItem> selectedItems = cartItemRepository.findByCartIdAndSelected(cart.getId(), true);
        if (selectedItems.isEmpty()) {
            return new BaseResponse<>("400", "请选择要购买的商品", null);
        }
        
        // 计算订单总金额
        BigDecimal totalAmount = BigDecimal.ZERO;
        for (CartItem item : selectedItems) {
            BigDecimal price = item.getPrice() != null ? new BigDecimal(item.getPrice()) : BigDecimal.ZERO;
            totalAmount = totalAmount.add(price.multiply(new BigDecimal(item.getNum())));
        }

        // 处理红包优惠
        Long couponId = getLongValue(body, "couponId", null);
        BigDecimal discountAmount = BigDecimal.ZERO;
        if (couponId != null) {
            Optional<Coupon> couponOpt = couponRepository.findById(couponId);
            if (couponOpt.isPresent()) {
                Coupon coupon = couponOpt.get();
                if (coupon.getUserId().equals(userId) && "UNUSED".equals(coupon.getStatus())) {
                    discountAmount = coupon.getAmount();
                    BigDecimal finalAmount = totalAmount.subtract(discountAmount);
                    if (finalAmount.compareTo(BigDecimal.ZERO) < 0) finalAmount = BigDecimal.ZERO;
                    totalAmount = finalAmount;
                    coupon.setStatus("USED");
                    couponRepository.save(coupon);
                } else {
                    couponId = null; // coupon invalid, ignore
                }
            } else {
                couponId = null;
            }
        }

        // 创建订单
        Order order = new Order();
        order.setOrderNo(generateOrderNo());
        order.setUserId(userId);
        order.setTotalAmount(totalAmount);
        order.setStatus("PENDING_PAYMENT");
        if (couponId != null) {
            order.setCouponId(couponId);
            order.setDiscountAmount(discountAmount);
        }
        
        // 收货信息（可从前端传入，这里使用默认值）
        order.setReceiverName(getStringValue(body, "receiverName", "收货人"));
        order.setReceiverPhone(getStringValue(body, "receiverPhone", "13800138000"));
        order.setReceiverAddress(getStringValue(body, "receiverAddress", "北京市朝阳区"));
        order.setRemark(getStringValue(body, "remark", null));
        
        order = orderRepository.save(order);
        
        // 创建订单明细
        for (CartItem cartItem : selectedItems) {
            OrderItem orderItem = new OrderItem();
            orderItem.setOrderId(order.getId());
            orderItem.setGoodsId(Long.parseLong(cartItem.getCode()));
            orderItem.setGoodsName(cartItem.getDescription());
            orderItem.setGoodsImage(cartItem.getImgUrl());
            orderItem.setPrice(cartItem.getPrice() != null ? new BigDecimal(cartItem.getPrice()) : BigDecimal.ZERO);
            orderItem.setQuantity(cartItem.getNum());
            orderItem.setColor(cartItem.getColor());
            orderItem.setSize(cartItem.getSize());
            orderItemRepository.save(orderItem);
        }
        
        // 从购物车中移除已下单的商品
        cartItemRepository.deleteAll(selectedItems);
        
        Map<String, Object> result = new HashMap<>();
        result.put("orderId", order.getId());
        result.put("orderNo", order.getOrderNo());
        result.put("totalAmount", totalAmount);
        
        return BaseResponse.success(result);
    }

    @PostMapping("/order/list")
    public BaseResponse<Map<String, Object>> queryOrderList(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        String status = getStringValue(body, "status", null);
        int page = getIntValue(body, "page", 0);
        int size = getIntValue(body, "size", 10);
        
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        
        Page<Order> orderPage;
        if (status != null && !status.isEmpty() && !"ALL".equals(status)) {
            orderPage = orderRepository.findByUserIdAndStatus(userId, status, pageable);
        } else {
            orderPage = orderRepository.findByUserId(userId, pageable);
        }
        
        List<Map<String, Object>> orderList = orderPage.getContent().stream().map(order -> {
            Map<String, Object> orderMap = convertOrderToMap(order);
            
            // 查询订单商品列表
            List<OrderItem> items = orderItemRepository.findByOrderId(order.getId());
            List<Map<String, Object>> itemList = items.stream().map(this::convertOrderItemToMap).collect(Collectors.toList());
            orderMap.put("items", itemList);
            
            return orderMap;
        }).collect(Collectors.toList());
        
        Map<String, Object> result = new HashMap<>();
        result.put("orderList", orderList);
        result.put("totalPages", orderPage.getTotalPages());
        result.put("totalElements", orderPage.getTotalElements());
        result.put("currentPage", page);
        
        return BaseResponse.success(result);
    }

    @PostMapping("/order/detail")
    public BaseResponse<Map<String, Object>> queryOrderDetail(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        Long orderId = getLongValue(body, "orderId", null);
        
        if (orderId == null) {
            return new BaseResponse<>("400", "订单ID不能为空", null);
        }
        
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isEmpty()) {
            return new BaseResponse<>("404", "订单不存在", null);
        }
        
        Order order = orderOpt.get();
        if (!order.getUserId().equals(userId)) {
            return new BaseResponse<>("403", "无权访问该订单", null);
        }
        
        Map<String, Object> orderMap = convertOrderToMap(order);
        
        // 查询订单商品列表
        List<OrderItem> items = orderItemRepository.findByOrderId(order.getId());
        List<Map<String, Object>> itemList = items.stream().map(this::convertOrderItemToMap).collect(Collectors.toList());
        orderMap.put("items", itemList);
        
        return BaseResponse.success(orderMap);
    }

    @PostMapping("/order/cancel")
    @Transactional
    public BaseResponse<String> cancelOrder(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        Long orderId = getLongValue(body, "orderId", null);
        
        if (orderId == null) {
            return new BaseResponse<>("400", "订单ID不能为空", null);
        }
        
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isEmpty()) {
            return new BaseResponse<>("404", "订单不存在", null);
        }
        
        Order order = orderOpt.get();
        if (!order.getUserId().equals(userId)) {
            return new BaseResponse<>("403", "无权操作该订单", null);
        }
        
        if ("COMPLETED".equals(order.getStatus()) || "CANCELLED".equals(order.getStatus())) {
            return new BaseResponse<>("400", "订单当前状态不允许取消", null);
        }
        
        order.setStatus("CANCELLED");
        orderRepository.save(order);
        
        return BaseResponse.success("订单已取消");
    }

    @PostMapping("/order/confirm")
    @Transactional
    public BaseResponse<String> confirmOrder(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        Long orderId = getLongValue(body, "orderId", null);
        
        if (orderId == null) {
            return new BaseResponse<>("400", "订单ID不能为空", null);
        }
        
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isEmpty()) {
            return new BaseResponse<>("404", "订单不存在", null);
        }
        
        Order order = orderOpt.get();
        if (!order.getUserId().equals(userId)) {
            return new BaseResponse<>("403", "无权操作该订单", null);
        }
        
        if (!"PENDING_RECEIPT".equals(order.getStatus())) {
            return new BaseResponse<>("400", "订单当前状态不允许确认收货", null);
        }
        
        order.setStatus("COMPLETED");
        order.setCompletedTime(LocalDateTime.now());
        orderRepository.save(order);
        
        return BaseResponse.success("确认收货成功");
    }

    @PostMapping("/order/delete")
    @Transactional
    public BaseResponse<String> deleteOrder(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        Long orderId = getLongValue(body, "orderId", null);
        
        if (orderId == null) {
            return new BaseResponse<>("400", "订单ID不能为空", null);
        }
        
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isEmpty()) {
            return new BaseResponse<>("404", "订单不存在", null);
        }
        
        Order order = orderOpt.get();
        if (!order.getUserId().equals(userId)) {
            return new BaseResponse<>("403", "无权操作该订单", null);
        }
        
        if (!"COMPLETED".equals(order.getStatus()) && !"CANCELLED".equals(order.getStatus())) {
            return new BaseResponse<>("400", "只有已完成或已取消的订单可以删除", null);
        }
        
        orderItemRepository.deleteByOrderId(orderId);
        orderRepository.deleteById(orderId);
        
        return BaseResponse.success("订单已删除");
    }

    @PostMapping("/order/pay")
    @Transactional
    public BaseResponse<String> payOrder(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        Long orderId = getLongValue(body, "orderId", null);
        
        if (orderId == null) {
            return new BaseResponse<>("400", "订单ID不能为空", null);
        }
        
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isEmpty()) {
            return new BaseResponse<>("404", "订单不存在", null);
        }
        
        Order order = orderOpt.get();
        if (!order.getUserId().equals(userId)) {
            return new BaseResponse<>("403", "无权操作该订单", null);
        }
        
        if (!"PENDING_PAYMENT".equals(order.getStatus())) {
            return new BaseResponse<>("400", "订单当前状态不允许支付", null);
        }
        
        // 模拟支付成功
        order.setStatus("PENDING_SHIPMENT");
        order.setPaymentTime(LocalDateTime.now());
        orderRepository.save(order);
        
        return BaseResponse.success("支付成功");
    }

    // Helper methods
    private String resolveUserId(Map<String, Object> body) {
        Object userIdObj = body.get("userId");
        return userIdObj == null || userIdObj.toString().isEmpty() ? "guest" : userIdObj.toString();
    }

    private String getStringValue(Map<String, Object> body, String key, String defaultValue) {
        Object value = body.get(key);
        return value == null ? defaultValue : value.toString();
    }

    private int getIntValue(Map<String, Object> body, String key, int defaultValue) {
        Object value = body.get(key);
        if (value == null) return defaultValue;
        try {
            return Integer.parseInt(value.toString());
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    private Long getLongValue(Map<String, Object> body, String key, Long defaultValue) {
        Object value = body.get(key);
        if (value == null) return defaultValue;
        try {
            return Long.parseLong(value.toString());
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    private String generateOrderNo() {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");
        String timestamp = LocalDateTime.now().format(formatter);
        String random = String.format("%04d", new Random().nextInt(10000));
        return "ORD" + timestamp + random;
    }

    private Map<String, Object> convertOrderToMap(Order order) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", order.getId());
        map.put("orderNo", order.getOrderNo());
        map.put("userId", order.getUserId());
        map.put("totalAmount", order.getTotalAmount());
        map.put("status", order.getStatus());
        map.put("statusText", getStatusText(order.getStatus()));
        map.put("createdAt", order.getCreatedAt());
        map.put("paymentTime", order.getPaymentTime());
        map.put("shipmentTime", order.getShipmentTime());
        map.put("completedTime", order.getCompletedTime());
        map.put("receiverName", order.getReceiverName());
        map.put("receiverPhone", order.getReceiverPhone());
        map.put("receiverAddress", order.getReceiverAddress());
        map.put("remark", order.getRemark());
        map.put("couponId", order.getCouponId());
        map.put("discountAmount", order.getDiscountAmount());
        return map;
    }

    private Map<String, Object> convertOrderItemToMap(OrderItem item) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", item.getId());
        map.put("orderId", item.getOrderId());
        map.put("goodsId", item.getGoodsId());
        map.put("goodsName", item.getGoodsName());
        map.put("goodsImage", item.getGoodsImage());
        map.put("price", item.getPrice());
        map.put("quantity", item.getQuantity());
        map.put("color", item.getColor());
        map.put("size", item.getSize());
        return map;
    }

    private String getStatusText(String status) {
        return switch (status) {
            case "PENDING_PAYMENT" -> "待付款";
            case "PENDING_SHIPMENT" -> "待发货";
            case "PENDING_RECEIPT" -> "待收货";
            case "COMPLETED" -> "已完成";
            case "CANCELLED" -> "已取消";
            default -> "未知状态";
        };
    }
}
