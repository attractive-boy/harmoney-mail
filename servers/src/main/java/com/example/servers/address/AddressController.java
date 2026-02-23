package com.example.servers.address;

import com.example.servers.BaseResponse;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.*;

@RestController
public class AddressController {

    private final UserAddressRepository addressRepository;

    public AddressController(UserAddressRepository addressRepository) {
        this.addressRepository = addressRepository;
    }

    @PostMapping("/address/list")
    public BaseResponse<List<Map<String, Object>>> listAddresses(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);

        if (addressRepository.countByUserId(userId) == 0) {
            seedDemoAddress(userId);
        }

        List<UserAddress> addresses = addressRepository.findByUserIdOrderByIsDefaultDescCreatedAtDesc(userId);
        List<Map<String, Object>> result = new ArrayList<>();
        for (UserAddress a : addresses) {
            result.add(addressToMap(a));
        }
        return BaseResponse.success(result);
    }

    @PostMapping("/address/add")
    @Transactional
    public BaseResponse<Map<String, Object>> addAddress(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        boolean isDefault = getBooleanValue(body, "isDefault", false);

        if (isDefault) {
            clearDefaultForUser(userId);
        }

        UserAddress address = new UserAddress();
        address.setUserId(userId);
        address.setName(getStringValue(body, "name", ""));
        address.setPhone(getStringValue(body, "phone", ""));
        address.setRegion(getStringValue(body, "region", ""));
        address.setDetail(getStringValue(body, "detail", ""));
        address.setDefault(isDefault);
        address.setLabel(getStringValue(body, "label", null));

        address = addressRepository.save(address);
        return BaseResponse.success(addressToMap(address));
    }

    @PostMapping("/address/update")
    @Transactional
    public BaseResponse<Map<String, Object>> updateAddress(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        Long id = getLongValue(body, "id", null);

        if (id == null) {
            return new BaseResponse<>("400", "id不能为空", null);
        }

        Optional<UserAddress> opt = addressRepository.findById(id);
        if (opt.isEmpty()) {
            return new BaseResponse<>("404", "地址不存在", null);
        }

        UserAddress address = opt.get();
        if (!address.getUserId().equals(userId)) {
            return new BaseResponse<>("403", "无权操作该地址", null);
        }

        boolean isDefault = getBooleanValue(body, "isDefault", false);
        if (isDefault) {
            clearDefaultForUser(userId);
        }

        address.setName(getStringValue(body, "name", address.getName()));
        address.setPhone(getStringValue(body, "phone", address.getPhone()));
        address.setRegion(getStringValue(body, "region", address.getRegion()));
        address.setDetail(getStringValue(body, "detail", address.getDetail()));
        address.setDefault(isDefault);
        address.setLabel(getStringValue(body, "label", address.getLabel()));

        address = addressRepository.save(address);
        return BaseResponse.success(addressToMap(address));
    }

    @PostMapping("/address/delete")
    @Transactional
    public BaseResponse<String> deleteAddress(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        Long id = getLongValue(body, "id", null);

        if (id == null) {
            return new BaseResponse<>("400", "id不能为空", null);
        }

        Optional<UserAddress> opt = addressRepository.findById(id);
        if (opt.isEmpty()) {
            return new BaseResponse<>("404", "地址不存在", null);
        }

        UserAddress address = opt.get();
        if (!address.getUserId().equals(userId)) {
            return new BaseResponse<>("403", "无权操作该地址", null);
        }

        boolean wasDefault = address.isDefault();
        addressRepository.delete(address);

        if (wasDefault) {
            List<UserAddress> remaining = addressRepository.findByUserIdOrderByIsDefaultDescCreatedAtDesc(userId);
            if (!remaining.isEmpty()) {
                UserAddress newDefault = remaining.get(0);
                newDefault.setDefault(true);
                addressRepository.save(newDefault);
            }
        }

        return BaseResponse.success("删除成功");
    }

    @PostMapping("/address/setDefault")
    @Transactional
    public BaseResponse<String> setDefault(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        Long id = getLongValue(body, "id", null);

        if (id == null) {
            return new BaseResponse<>("400", "id不能为空", null);
        }

        Optional<UserAddress> opt = addressRepository.findById(id);
        if (opt.isEmpty()) {
            return new BaseResponse<>("404", "地址不存在", null);
        }

        UserAddress address = opt.get();
        if (!address.getUserId().equals(userId)) {
            return new BaseResponse<>("403", "无权操作该地址", null);
        }

        clearDefaultForUser(userId);
        address.setDefault(true);
        addressRepository.save(address);

        return BaseResponse.success("设置成功");
    }

    private void clearDefaultForUser(String userId) {
        Optional<UserAddress> currentDefault = addressRepository.findByUserIdAndIsDefaultTrue(userId);
        if (currentDefault.isPresent()) {
            UserAddress prev = currentDefault.get();
            prev.setDefault(false);
            addressRepository.save(prev);
        }
    }

    private void seedDemoAddress(String userId) {
        UserAddress address = new UserAddress();
        address.setUserId(userId);
        address.setName("张三");
        address.setPhone("13800138000");
        address.setRegion("北京市朝阳区");
        address.setDetail("建国路88号SOHO现代城");
        address.setDefault(true);
        address.setLabel("家");
        addressRepository.save(address);
    }

    private Map<String, Object> addressToMap(UserAddress a) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", a.getId());
        map.put("userId", a.getUserId());
        map.put("name", a.getName());
        map.put("phone", a.getPhone());
        map.put("region", a.getRegion());
        map.put("detail", a.getDetail());
        map.put("isDefault", a.isDefault());
        map.put("label", a.getLabel() != null ? a.getLabel() : "");
        map.put("createdAt", a.getCreatedAt());
        return map;
    }

    private String resolveUserId(Map<String, Object> body) {
        Object userIdObj = body.get("userId");
        return userIdObj == null || userIdObj.toString().isEmpty() ? "guest" : userIdObj.toString();
    }

    private String getStringValue(Map<String, Object> body, String key, String defaultValue) {
        Object value = body.get(key);
        return value == null ? defaultValue : value.toString();
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

    private boolean getBooleanValue(Map<String, Object> body, String key, boolean defaultValue) {
        Object value = body.get(key);
        if (value == null) return defaultValue;
        if (value instanceof Boolean) return (Boolean) value;
        return Boolean.parseBoolean(value.toString());
    }
}
