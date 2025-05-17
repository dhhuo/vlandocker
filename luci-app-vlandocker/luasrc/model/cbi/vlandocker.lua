local sys = require "luci.sys"
local m = Map("vlandocker", "VLAN & Docker Setup", "配置 VLAN 和 Docker macvlan 网络，并启用 DHCP 服务。")

-- 物理接口输入
local iface = m:section(SimpleSection, "iface_section", "物理接口名称")
local iface_val = iface:option(Value, "iface", "物理接口")
iface_val.default = "eth3"
iface_val.rmempty = false

-- VLAN 配置表
local s = m:section(TypedSection, "vlan", "VLAN 配置", "添加多个 VLAN 条目")
s.addremove = true
s.anonymous = true

local vlanid = s:option(Value, "id", "VLAN ID")
vlanid.datatype = "range(1,4094)"
vlanid.rmempty = false

local subnet = s:option(Value, "subnet", "子网 (格式: 192.168.x.1/24)")
subnet.datatype = "ip4addr"
subnet.rmempty = false

-- 应用按钮
local apply = m:section(SimpleSection)
local btn = apply:option(Button, "apply", "应用配置")
btn.inputstyle = "apply"
btn.write = function()
  local vlans = {}
  m.uci:foreach("vlandocker", "vlan", function(s)
    table.insert(vlans, {id=s.id, subnet=s.subnet})
  end)

  local iface_name = iface_val:formvalue()

  local tmpfile = "/tmp/vlandocker_config"
  local f = io.open(tmpfile, "w")
  if not f then
    luci.http.write("无法写入临时文件！")
    return
  end
  f:write(iface_name .. "\n")
  for _, v in ipairs(vlans) do
    f:write(v.id .. " " .. v.subnet .. "\n")
  end
  f:close()

  sys.call("/usr/lib/lua/luci/vlandocker_apply.sh " .. tmpfile .. " > /tmp/vlandocker.log 2>&1 &")
end

return m
