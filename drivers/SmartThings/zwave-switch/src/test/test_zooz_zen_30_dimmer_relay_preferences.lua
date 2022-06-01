local test = require "integration_test"
local t_utils = require "integration_test.utils"
local zw = require "st.zwave"
local zw_test_utils = require "integration_test.zwave_test_utils"
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version = 4 })

local preferencesMap = require "preferences"

local zooz_zen_dimmer_relay_endpoints = {
  {
    command_classes = {
      { value = zw.SWITCH_BINARY },
      { value = zw.SWITCH_MULTILEVEL },
      { value = zw.CENTRAL_SCENE }
    }
  },
  {
    command_classes = {
      { value = zw.SWITCH_BINARY }
    }
  }
}

local zooz_zen_dimmer_relay = test.mock_device.build_test_zwave_device({
  profile = t_utils.get_profile_definition("zooz-zen-30-dimmer-relay.yml"),
  zwave_endpoints = zooz_zen_dimmer_relay_endpoints,
  zwave_manufacturer_id = 0x027A,
  zwave_product_type = 0xA000,
  zwave_product_id = 0xA008
})

local function test_init()
  test.mock_device.add_test_device(zooz_zen_dimmer_relay)
end
test.set_test_init_function(test_init)

do
  local new_param_value = 1
  test.register_coroutine_test(
    "Parameter should be updated in the device configuration after change",
    function()
      local parameters = preferencesMap.get_device_parameters(zooz_zen_dimmer_relay)
      for id, value in pairs(parameters) do
        test.socket.zwave:__set_channel_ordering("relaxed")
        test.socket.device_lifecycle:__queue_receive(
          zooz_zen_dimmer_relay:generate_info_changed({
            preferences = {
              [id] = new_param_value
            }
          })
        )
        test.socket.zwave:__expect_send(
          zw_test_utils.zwave_test_build_send_command(
            zooz_zen_dimmer_relay,
            Configuration:Set({
              parameter_number = parameters[id].parameter_number,
              configuration_value = new_param_value,
              size = parameters[id].size
            })
          )
        )
      end
    end
  )
end

test.run_registered_tests()
