classdef Controller < handle
    properties
        viewObj;
        modelObj;

        ChannelNameMaps;
        ChannelEnableMaps;
        ChannelRangeMaps;
        ChannelCouplingMaps;
        ChannelOffsetMaps;
        TriggerDirectionMaps;
    end

    methods
        % Constructor of 'Controller' class
        function obj = Controller(viewObj,modelObj)
            obj.viewObj = viewObj;
            obj.modelObj = modelObj;
            obj.constructMaps();
        end

        % Create mappings
        function constructMaps(obj,~,~)
            % Create "Channel Name" mapping
            obj.ChannelNameMaps = containers.Map;
            obj.ChannelNameMaps("A") = obj.modelObj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_A;
            obj.ChannelNameMaps("B") = obj.modelObj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_B;
            obj.ChannelNameMaps("C") = obj.modelObj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_C;
            obj.ChannelNameMaps("D") = obj.modelObj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_D;
            obj.ChannelNameMaps("E") = obj.modelObj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_E;
            obj.ChannelNameMaps("F") = obj.modelObj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_F;
            obj.ChannelNameMaps("G") = obj.modelObj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_G;
            obj.ChannelNameMaps("H") = obj.modelObj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_H;

            % Create "Channel Enable" mapping
            obj.ChannelEnableMaps = containers.Map;
            obj.ChannelEnableMaps("0") = PicoConstants.FALSE;
            obj.ChannelEnableMaps("1") = PicoConstants.TRUE;

            % Create "Channel Coupling" mapping
            obj.ChannelCouplingMaps = containers.Map;
            obj.ChannelCouplingMaps("DC") = obj.modelObj.ps4000aEnuminfo.enPS4000ACoupling.PS4000A_DC;
            obj.ChannelCouplingMaps("AC") = obj.modelObj.ps4000aEnuminfo.enPS4000ACoupling.PS4000A_AC;

            % Create "Channel Range" mapping
            obj.ChannelRangeMaps = containers.Map;
            obj.ChannelRangeMaps("10 mV") = obj.modelObj.ps4000aEnuminfo.enPS4000ARange.PS4000A_10MV;
            obj.ChannelRangeMaps("20 mV") = obj.modelObj.ps4000aEnuminfo.enPS4000ARange.PS4000A_20MV;
            obj.ChannelRangeMaps("50 mV") = obj.modelObj.ps4000aEnuminfo.enPS4000ARange.PS4000A_50MV;
            obj.ChannelRangeMaps("100 mV") = obj.modelObj.ps4000aEnuminfo.enPS4000ARange.PS4000A_100MV;
            obj.ChannelRangeMaps("200 mV") = obj.modelObj.ps4000aEnuminfo.enPS4000ARange.PS4000A_200MV;
            obj.ChannelRangeMaps("500 mV") = obj.modelObj.ps4000aEnuminfo.enPS4000ARange.PS4000A_500MV;
            obj.ChannelRangeMaps("1 V") = obj.modelObj.ps4000aEnuminfo.enPS4000ARange.PS4000A_1V;
            obj.ChannelRangeMaps("2 V") = obj.modelObj.ps4000aEnuminfo.enPS4000ARange.PS4000A_2V;
            obj.ChannelRangeMaps("5 V") = obj.modelObj.ps4000aEnuminfo.enPS4000ARange.PS4000A_5V;
            obj.ChannelRangeMaps("10 V") = obj.modelObj.ps4000aEnuminfo.enPS4000ARange.PS4000A_10V;
            obj.ChannelRangeMaps("20 V") = obj.modelObj.ps4000aEnuminfo.enPS4000ARange.PS4000A_20V;
            obj.ChannelRangeMaps("50 V") = obj.modelObj.ps4000aEnuminfo.enPS4000ARange.PS4000A_50V;

            % Create "Channel Offset" mapping
            obj.ChannelOffsetMaps = containers.Map;
            obj.ChannelOffsetMaps("0.0") = 0.0;

            % Create "Trigger Direction" mapping
            obj.TriggerDirectionMaps = containers.Map;
            obj.TriggerDirectionMaps("ABOVE") = obj.modelObj.ps4000aEnuminfo.enPS4000AThresholdDirection.PS4000A_ABOVE;
            obj.TriggerDirectionMaps("BELOW") = obj.modelObj.ps4000aEnuminfo.enPS4000AThresholdDirection.PS4000A_BELOW;
            obj.TriggerDirectionMaps("RISING") = obj.modelObj.ps4000aEnuminfo.enPS4000AThresholdDirection.PS4000A_RISING;
            obj.TriggerDirectionMaps("FALLING") = obj.modelObj.ps4000aEnuminfo.enPS4000AThresholdDirection.PS4000A_FALLING;
            obj.TriggerDirectionMaps("RISING_OR_FALLING") = obj.modelObj.ps4000aEnuminfo.enPS4000AThresholdDirection.PS4000A_RISING_OR_FALLING;
        end


        
        function controller_updateAutoTriggerEnable(obj,~,~)
            obj.modelObj.callback_updateAutoTriggerEnable();
        end

        function controller_updateAutoTriggerSetting(obj,src,~)
            AutoTriggerVal = src.Value;
            obj.modelObj.callback_updateAutoTriggerSetting(AutoTriggerVal);
        end

        function controller_updateTriggerChannel(obj,src,~)
            TriggerChannelVal = src.Value;
            val = obj.ChannelNameMaps(TriggerChannelVal);
            obj.modelObj.callback_updateTriggerChannelSetting(val);
        end

        function controller_updateTriggerThreshold(obj,src,~)
            TriggerThresholdVal = src.Value;
            obj.modelObj.callback_updateTriggerThresholdSetting(TriggerThresholdVal);
        end

        function controller_updateSimpleTriggerDirection(obj,src,~)
            SimpleTriggerDirectionVal = src.Value;
            val = obj.TriggerDirectionMaps(SimpleTriggerDirectionVal);
            obj.modelObj.callback_updateSimpleTriggerDirectionSetting(val);
        end

        function controller_updatePreTrigger(obj,src,~)
            PreTriggerVal = src.Value*1e3; % convert 'ms' to 'samples'
            obj.modelObj.callback_updatePreTriggerSetting(PreTriggerVal);
        end

        function controller_updatePostTrigger(obj,src,~)
            PostTriggerVal = src.Value*1e3; % convert 'ms' to 'samples'
            obj.modelObj.callback_updatePostTriggerSetting(PostTriggerVal);
        end




















        function controller_connectDevice(obj,~,~)
            obj.modelObj.callback_connectDevice();
        end

        function controller_disconnectDevice(obj,~,~)
            obj.modelObj.callback_disconnectDevice();
        end

        function controller_updateChannelSettings(obj,~,~)
            obj.modelObj.callback_changeChannelSettings;
        end

        function controller_updateChannelRangeSettings(obj,~,~)
            obj.modelObj.callback_changeChannelRange;
        end

        function controller_updateTriggerSettings(obj,~,~)
            obj.modelObj.callback_updateTriggerSettings();
        end



        function controller_updateEnableCheckBox(obj,~,~)
            obj.modelObj.callback_updateEnableCheckBox();
        end
        function controller_runCollecting(obj,~,~)
            obj.modelObj.callback_captureData();
        end
        function controller_stopCaptureData(obj,src,~)
            obj.modelObj.callback_stopCaptureData(src);
        end
        function controller_clearAxes(obj,~,~)
            obj.modelObj.callback_clearAxes();
        end
        function controller_saveData(obj,~,~)
            obj.modelObj.callback_saveData();
        end
        function controller_loadMatDataFile(obj,~,~)
            obj.modelObj.callback_loadMatDataFile();
        end
        function controller_closeApp(obj,~,~)
            obj.modelObj.callback_closeApp();
        end
    end
end
