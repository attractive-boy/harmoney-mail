package com.example.servers.mine;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.example.servers.BaseResponse;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MineController {

    private final MineFunctionRepository functionRepository;
    private final MineTabRepository tabRepository;

    public MineController(MineFunctionRepository functionRepository,
                          MineTabRepository tabRepository) {
        this.functionRepository = functionRepository;
        this.tabRepository = tabRepository;
    }

    @PostMapping("/mine/queryMineInfo")
    public BaseResponse<Map<String, Object>> queryMineInfo() {
        List<MineFunction> functionList = functionRepository.findAllByOrderByIdAsc();
        List<MineTab> tabList = tabRepository.findAllByOrderByIdAsc();
        Map<String, Object> data = new HashMap<>();
        data.put("functionList", functionList);
        data.put("tabList", tabList);
        return BaseResponse.success(data);
    }
}

