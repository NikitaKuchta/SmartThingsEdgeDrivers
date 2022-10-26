-- Copyright 2022 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
local capabilities = require "st.capabilities"
local st_device = require "st.device"
local clusters = require "st.zigbee.zcl.clusters"
local OnOff = clusters.OnOff

local PARENT_ENDPOINT = 1

local MULTI_SWITCH_NO_MASTER_FINGERPRINTS = {
  { mfr = "DAWON_DNS", model = "PM-S240-ZB", children = 1 },
  { mfr = "DAWON_DNS", model = "PM-S240R-ZB", children = 1 },
  { mfr = "DAWON_DNS", model = "PM-S250-ZB", children = 1 },
  { mfr = "DAWON_DNS", model = "PM-S340-ZB", children = 2 },
  { mfr = "DAWON_DNS", model = "PM-S340R-ZB", children = 2 },
  { mfr = "DAWON_DNS", model = "PM-S350-ZB", children = 2 },
  { mfr = "DAWON_DNS", model = "ST-S250-ZB", children = 1 },
  { mfr = "DAWON_DNS", model = "ST-S350-ZB", children = 2 },
  { mfr = "ORVIBO", model = "074b3ffba5a045b7afd94c47079dd553", children = 2 },
  { mfr = "ORVIBO", model = "9f76c9f31b4c4a499e3aca0977ac4494", children = 3 },
  { mfr = "REXENSE", model = "HY0002", children = 2 },
  { mfr = "REXENSE", model = "HY0003", children = 3 },
  { mfr = "REX", model = "HY0096", children = 2 },
  { mfr = "REX", model = "HY0097", children = 3 },
  { mfr = "HEIMAN", model = "HS2SW2L-EFR-3.0", children = 2 },
  { mfr = "HEIMAN", model = "HS2SW3L-EFR-3.0", children = 3 },
  { mfr = "eWeLink", model = "ZB-SW02", children = 2 },
  { mfr = "eWeLink", model = "ZB-SW03", children = 3 },
  { mfr = "eWeLink", model = "ZB-SW04", children = 4 },
  { model = "E220-KR2N0Z0-HA", children = 1 },
  { model = "E220-KR3N0Z0-HA", children = 2 },
  { model = "E220-KR4N0Z0-HA", children = 3 },
  { model = "E220-KR5N0Z0-HA", children = 4 },
  { model = "E220-KR6N0Z0-HA", children = 5 }
}

local function is_multi_switch_no_master(opts, driver, device)
  for _, fingerprint in ipairs(MULTI_SWITCH_NO_MASTER_FINGERPRINTS) do
    if device:get_manufacturer() == nil and device:get_model() == fingerprint.model then
      return true
    elseif device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      return true
    end
  end
  return false
end

local function get_children_amount(device)
  for _, fingerprint in ipairs(MULTI_SWITCH_NO_MASTER_FINGERPRINTS) do
    if device:get_model() == fingerprint.model then
      return fingerprint.children
    end
  end
end

local function device_added(driver, device, event)
  if device.network_type == st_device.NETWORK_TYPE_ZIGBEE then
    local children_amount = get_children_amount(device)
    for i = 2, children_amount+1 do
      local device_name_without_number = string.sub(driver.label, 0,-2)
      local name = string.format("%s%d", device_name_without_number, i)
      local metadata = {
        type = "EDGE_CHILD",
        label = name,
        profile = "multi-switch-no-master",
        parent_device_id = device.id,
        parent_assigned_child_key = string.format("%02X", i),
        vendor_provided_label = name,
      }
      driver:try_create_device(metadata)
    end
  end
end

local function find_child(parent, ep_id)
  if ep_id == 1 then
    return parent
  else
    return parent:get_child_by_parent_assigned_key(string.format("%02X", ep_id))
  end
end

local function component_to_endpoint(device, component)
  return PARENT_ENDPOINT
end

local function device_init(driver, device, event)
  if device.network_type == st_device.NETWORK_TYPE_ZIGBEE then
    device:set_find_child(find_child)
    device:set_component_to_endpoint_fn(component_to_endpoint)
  end
end

local function do_refresh(self, device)
  device:send(OnOff.attributes.OnOff:read(device))
end
  
local multi_switch_no_master = {
  NAME = "multi switch no master",
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = do_refresh
    }
  },
  lifecycle_handlers = {
    init = device_init,
    added = device_added
  },
  can_handle = is_multi_switch_no_master
}

return multi_switch_no_master
  