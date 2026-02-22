package com.example.servers.auth;

import com.example.servers.BaseResponse;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestHeader;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@RestController
public class AuthController {

    private final UserRepository userRepository;

    public AuthController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @PostMapping("/common/register")
    public BaseResponse<Map<String, Object>> register(@RequestBody RegisterRequest request) {
        String account = request == null ? null : safeTrim(request.account);
        String password = request == null ? null : safeTrim(request.password);

        if (account == null || account.isEmpty()) {
            return new BaseResponse<>("400", "请输入手机号或邮箱", null);
        }
        if (password == null || password.isEmpty()) {
            return new BaseResponse<>("400", "请输入密码", null);
        }
        if (!isValidPassword(password)) {
            return new BaseResponse<>("400", "密码至少8位且包含字母和数字", null);
        }

        String email = null;
        String phone = null;
        if (account.contains("@")) {
            if (!isValidEmail(account)) {
                return new BaseResponse<>("400", "邮箱格式不正确", null);
            }
            email = account.toLowerCase();
            if (userRepository.existsByEmail(email)) {
                return new BaseResponse<>("409", "该邮箱已注册", null);
            }
        } else {
            if (!isValidPhone(account)) {
                return new BaseResponse<>("400", "手机号格式不正确", null);
            }
            phone = account;
            if (userRepository.existsByPhone(phone)) {
                return new BaseResponse<>("409", "该手机号已注册", null);
            }
        }

        String salt = PasswordUtil.generateSalt();
        String hash = PasswordUtil.hashPassword(password, salt);
        User user = new User(email, phone, hash, salt, Instant.now());
        String token = TokenUtil.generateToken();
        user.setAuthToken(token);
        String accountValue = email != null ? email : phone;
        user.setNickname(accountValue);
        user.setPoints(200);
        user.setCredit(1200);
        userRepository.save(user);

        Map<String, Object> data = new HashMap<>();
        data.put("id", user.getId());
        data.put("email", user.getEmail());
        data.put("phone", user.getPhone());
        data.put("account", accountValue);
        data.put("token", token);
        data.put("nickname", user.getNickname());
        data.put("points", user.getPoints());
        data.put("credit", user.getCredit());
        return BaseResponse.success(data);
    }

    @PostMapping("/common/login")
    public BaseResponse<Map<String, Object>> login(@RequestBody LoginRequest request) {
        String account = request == null ? null : safeTrim(request.account);
        String password = request == null ? null : safeTrim(request.password);

        if (account == null || account.isEmpty()) {
            return new BaseResponse<>("400", "请输入手机号或邮箱", null);
        }
        if (password == null || password.isEmpty()) {
            return new BaseResponse<>("400", "请输入密码", null);
        }

        User user = account.contains("@")
                ? userRepository.findByEmail(account.toLowerCase()).orElse(null)
                : userRepository.findByPhone(account).orElse(null);

        if (user == null) {
            return new BaseResponse<>("401", "账号或密码错误", null);
        }

        String hash = PasswordUtil.hashPassword(password, user.getPasswordSalt());
        if (!hash.equals(user.getPasswordHash())) {
            return new BaseResponse<>("401", "账号或密码错误", null);
        }

        String token = TokenUtil.generateToken();
        user.setAuthToken(token);
        userRepository.save(user);

        Map<String, Object> data = new HashMap<>();
        data.put("id", user.getId());
        data.put("email", user.getEmail());
        data.put("phone", user.getPhone());
        data.put("account", user.getEmail() != null ? user.getEmail() : user.getPhone());
        data.put("token", token);
        data.put("nickname", user.getNickname());
        data.put("points", user.getPoints());
        data.put("credit", user.getCredit());
        return BaseResponse.success(data);
    }

    @PostMapping("/common/profile")
    public BaseResponse<Map<String, Object>> profile(@RequestHeader(value = "Authorization", required = false) String authorization) {
        String token = extractBearerToken(authorization);
        if (token == null || token.isEmpty()) {
            return new BaseResponse<>("401", "未授权，请重新登录", null);
        }

        User user = userRepository.findByAuthToken(token).orElse(null);

        if (user == null) {
            return new BaseResponse<>("401", "未授权，请重新登录", null);
        }

        Map<String, Object> data = new HashMap<>();
        data.put("id", user.getId());
        data.put("email", user.getEmail());
        data.put("phone", user.getPhone());
        data.put("account", user.getEmail() != null ? user.getEmail() : user.getPhone());
        data.put("nickname", user.getNickname());
        data.put("points", user.getPoints());
        data.put("credit", user.getCredit());
        return BaseResponse.success(data);
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }

    private static boolean isValidPhone(String phone) {
        return phone != null && phone.matches("^1\\d{10}$");
    }

    private static boolean isValidEmail(String email) {
        return email != null && email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");
    }

    private static boolean isValidPassword(String password) {
        return password != null && password.matches("^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$");
    }

    static class RegisterRequest {
        public String account;
        public String password;
    }

    static class LoginRequest {
        public String account;
        public String password;
    }

    private static String extractBearerToken(String authorization) {
        if (authorization == null || authorization.isEmpty()) {
            return null;
        }
        String prefix = "Bearer ";
        if (authorization.startsWith(prefix)) {
            return authorization.substring(prefix.length()).trim();
        }
        return authorization.trim();
    }
}
