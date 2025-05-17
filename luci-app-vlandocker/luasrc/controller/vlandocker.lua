module("luci.controller.vlandocker", package.seeall)

function index()
  if not nixio.fs.access("/etc/config/vlandocker") then
    return
  end

  entry({"admin", "network", "vlandocker"}, cbi("vlandocker"), _("VLAN Docker Setup"), 30).dependent = true
  entry({"admin", "network", "vlandocker", "status"}, template("vlandocker/status"), _("Status"), 40).leaf = true
end
