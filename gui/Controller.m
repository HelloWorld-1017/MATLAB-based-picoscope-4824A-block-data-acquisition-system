classdef Controller < handle
    properties
        viewObj;
        modelObj;
    end

    methods
        % Constructor of 'Controller' class 
        function obj = Controller(viewObj,modelObj)
            obj.viewObj = viewObj;
            obj.modelObj = modelObj;
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

        function controller_updateAutoTriggerEnable(obj,~,~)
            obj.modelObj.callback_updateAutoTriggerEnable();
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
