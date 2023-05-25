classdef Model < handle
    properties
        viewObj;
        ps4000aStructs;
        ps4000aEnuminfo;
        ps4000aDeviceObj;
        status;
        RriggerGroupObj;
        timeMs;
        timebaseIndex;
        BlockData;
        BlockGroupObj;
        timeIntervalNanoSeconds;
        maxSamples;
        numSamples;
        AvailableChannels = ["A","B","C","D","E","F","G","H"];
        hasDataChannels;
        hasDataStruct;
    end

    properties(Hidden)
        ChannelNameMaps;
        ChannelEnableMaps;
        ChannelRangeMaps;
        ChannelCouplingMaps;
        ChannelOffsetMaps;
        TriggerDirectionMaps;

        ChannelUnits;
        ChannelRanges;
    end

    events
        notifier_DeviceConnectionStateChanged;
        notifier_updateChannelSettings;
        notifier_updateChannelRangeSettings;
        notifier_updateAutoTrigger;
        notifier_updateTriggerSettings;
        notifier_updateChannelEnable;

        notifier_DataCollectedSuccessfully;
        notifier_loadDataSuccessfully;
        notifier_collectingData;
        notifier_collectionAborting;
        notifier_clearAxes;
        notifier_AxesNotEmpty;
    end

    methods
        % Constructor of 'Model' class
        function obj = Model(viewObj)
            obj.viewObj = viewObj;
        end

        % Connect device function
        function callback_connectDevice(obj,~,~)
            % Load configuration information.
            % Setup paths and also load struct and enumeration information.
            % Enumeration values are required for certain function calls.
            [obj.ps4000aStructs,obj.ps4000aEnuminfo] = ps4000aSetConfig(); % DO NOT EDIT THIS LINE.

            % Create a device object.
            % The serial number can be specified as a second input parameter.
            obj.ps4000aDeviceObj = icdevice('picotech_ps4000a_generic.mdd','');

            obj.constructMaps();
            connect(obj.ps4000aDeviceObj);
            obj.callback_updateChannelSettings();
            obj.callback_updateTriggerSettings();
            obj.notify('notifier_DeviceConnectionStateChanged');
        end

        % Create mappings
        function constructMaps(obj,~,~)
            % Create "Channel Name" mapping
            obj.ChannelNameMaps = containers.Map;
            obj.ChannelNameMaps("A") = obj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_A;
            obj.ChannelNameMaps("B") = obj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_B;
            obj.ChannelNameMaps("C") = obj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_C;
            obj.ChannelNameMaps("D") = obj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_D;
            obj.ChannelNameMaps("E") = obj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_E;
            obj.ChannelNameMaps("F") = obj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_F;
            obj.ChannelNameMaps("G") = obj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_G;
            obj.ChannelNameMaps("H") = obj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_H;

            % Create "Channel Enable" mapping
            obj.ChannelEnableMaps = containers.Map;
            obj.ChannelEnableMaps("0") = PicoConstants.FALSE;
            obj.ChannelEnableMaps("1") = PicoConstants.TRUE;

            % Create "Channel Coupling" mapping
            obj.ChannelCouplingMaps = containers.Map;
            obj.ChannelCouplingMaps("DC") = obj.ps4000aEnuminfo.enPS4000ACoupling.PS4000A_DC;
            obj.ChannelCouplingMaps("AC") = obj.ps4000aEnuminfo.enPS4000ACoupling.PS4000A_AC;

            % Create "Channel Range" mapping
            obj.ChannelRangeMaps = containers.Map;
            obj.ChannelRangeMaps("10 mV") = obj.ps4000aEnuminfo.enPS4000ARange.PS4000A_10MV;
            obj.ChannelRangeMaps("20 mV") = obj.ps4000aEnuminfo.enPS4000ARange.PS4000A_20MV;
            obj.ChannelRangeMaps("50 mV") = obj.ps4000aEnuminfo.enPS4000ARange.PS4000A_50MV;
            obj.ChannelRangeMaps("100 mV") = obj.ps4000aEnuminfo.enPS4000ARange.PS4000A_100MV;
            obj.ChannelRangeMaps("200 mV") = obj.ps4000aEnuminfo.enPS4000ARange.PS4000A_200MV;
            obj.ChannelRangeMaps("500 mV") = obj.ps4000aEnuminfo.enPS4000ARange.PS4000A_500MV;
            obj.ChannelRangeMaps("1 V") = obj.ps4000aEnuminfo.enPS4000ARange.PS4000A_1V;
            obj.ChannelRangeMaps("2 V") = obj.ps4000aEnuminfo.enPS4000ARange.PS4000A_2V;
            obj.ChannelRangeMaps("5 V") = obj.ps4000aEnuminfo.enPS4000ARange.PS4000A_5V;
            obj.ChannelRangeMaps("10 V") = obj.ps4000aEnuminfo.enPS4000ARange.PS4000A_10V;
            obj.ChannelRangeMaps("20 V") = obj.ps4000aEnuminfo.enPS4000ARange.PS4000A_20V;
            obj.ChannelRangeMaps("50 V") = obj.ps4000aEnuminfo.enPS4000ARange.PS4000A_50V;

            % Create "Channel Offset" mapping
            obj.ChannelOffsetMaps = containers.Map;
            obj.ChannelOffsetMaps("0.0") = 0.0;

            % Create "Trigger Direction" mapping
            obj.TriggerDirectionMaps = containers.Map;
            obj.TriggerDirectionMaps("ABOVE") = obj.ps4000aEnuminfo.enPS4000AThresholdDirection.PS4000A_ABOVE;
            obj.TriggerDirectionMaps("BELOW") = obj.ps4000aEnuminfo.enPS4000AThresholdDirection.PS4000A_BELOW;
            obj.TriggerDirectionMaps("RISING") = obj.ps4000aEnuminfo.enPS4000AThresholdDirection.PS4000A_RISING;
            obj.TriggerDirectionMaps("FALLING") = obj.ps4000aEnuminfo.enPS4000AThresholdDirection.PS4000A_FALLING;
            obj.TriggerDirectionMaps("RISING_OR_FALLING") = obj.ps4000aEnuminfo.enPS4000AThresholdDirection.PS4000A_RISING_OR_FALLING;
        end

        % Disconnect device function
        function callback_disconnectDevice(obj,~,~)
            disconnect(obj.ps4000aDeviceObj);
            obj.notify('notifier_DeviceConnectionStateChanged');% Notify View to update display state
        end

        % Overload the `CloseRequestFcn` function of the uifigure
        function callback_closeApp(obj,~,~)
            selection = uiconfirm(obj.viewObj.fig,'Close the App?',...
                'Confirmation');
            switch selection
                case 'OK'
                    % Disconnect device
                    try
                        disconnect(obj.ps4000aDeviceObj);
                    catch
                    end
                    % Delete the GUI
                    delete(obj.viewObj.fig);
                case 'Cancel'
                    return
            end
        end

        % Obtain the range and unit of each channel
        function obtainRangeAndUnit(obj)
            for i = 1:numel(obj.AvailableChannels)
                ChannelName = obj.AvailableChannels(i);
                eval(strcat("[obj.ChannelRanges.",ChannelName,",obj.ChannelUnits.",ChannelName, ...
                    "] = invoke(obj.ps4000aDeviceObj,'getChannelInputRangeAndUnits',obj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_",ChannelName,");"));
            end
        end

        % Update trigger settings function
        function callback_updateTriggerSettings(obj,~,~)
            % Set simple trigger
            obj.RriggerGroupObj = get(obj.ps4000aDeviceObj,'Trigger');
            obj.RriggerGroupObj = obj.RriggerGroupObj(1);

            % Set the autoTriggerMs property
            set(obj.RriggerGroupObj,'autoTriggerMs',obj.viewObj.TriggerSettings.AutoTrigger.Value);
            [obj.status.setSimpleTrigger] = invoke(obj.RriggerGroupObj,'setSimpleTrigger', ...
                obj.ChannelNameMaps(obj.viewObj.TriggerSettings.SimpleTriggerChannel.Value),...
                obj.viewObj.TriggerSettings.SimpleTriggerThreshold.Value, ...
                obj.TriggerDirectionMaps(obj.viewObj.TriggerSettings.SimpleTriggerDirection.Value));

            % Set block parameters and capture data
            obj.BlockGroupObj = get(obj.ps4000aDeviceObj, 'Block');
            obj.BlockGroupObj = obj.BlockGroupObj(1);

            set(obj.ps4000aDeviceObj,'numPreTriggerSamples',obj.viewObj.TriggerSettings.PreTrigger.Value*1e3);
            set(obj.ps4000aDeviceObj,'numPostTriggerSamples',obj.viewObj.TriggerSettings.PostTrigger.Value*1e3);

            obj.notify('notifier_updateTriggerSettings');
            disp('Update trigger settings!')
        end

        % Update channel settings function
        function callback_updateChannelSettings(obj,~,~)
            for i = 1:numel(obj.AvailableChannels)
                ChannelName = obj.AvailableChannels(i);
                [obj.status.setChannel.(ChannelName)] = invoke(obj.ps4000aDeviceObj, ...
                    'ps4000aSetChannel', ...
                    obj.ChannelNameMaps(obj.viewObj.ChannelSettings.(ChannelName).ChannelName.Text(end)),...
                    obj.ChannelEnableMaps(num2str(obj.viewObj.ChannelSettings.(ChannelName).ChannelEnable.Value)),...
                    obj.ChannelCouplingMaps(obj.viewObj.ChannelSettings.(ChannelName).ChannelCoupling.Value),...
                    obj.ChannelRangeMaps(obj.viewObj.ChannelSettings.(ChannelName).ChannelRange.Value),...
                    obj.ChannelOffsetMaps(num2str(obj.viewObj.ChannelSettings.(ChannelName).ChannelOffset.Value)));
            end
            obj.obtainRangeAndUnit();
            disp("Update channel settings!")
        end

        % Set timebase function
        function setTimeBase(obj)
            obj.status.getTimebase2 = PicoStatus.PICO_INVALID_TIMEBASE; % 14
            obj.timebaseIndex = get(obj.ps4000aDeviceObj, 'timebase');  % 79
            while (obj.status.getTimebase2 == PicoStatus.PICO_INVALID_TIMEBASE)
                [obj.status.getTimebase2, obj.timeIntervalNanoSeconds, obj.maxSamples] = ...
                    invoke(obj.ps4000aDeviceObj, 'ps4000aGetTimebase2', obj.timebaseIndex, 0);
                if (obj.status.getTimebase2 == PicoStatus.PICO_OK)
                    break
                else
                    obj.timebaseIndex = obj.timebaseIndex + 1;
                end
            end
            fprintf('Timebase index: %d\n',obj.timebaseIndex);
            set(obj.ps4000aDeviceObj,'timebase',obj.timebaseIndex);
        end

        % Collect data function
        function callback_captureData(obj,~,~)
            obj.notify('notifier_collectingData');
            pause(0.001);

            % Verify timebase index and maximum number of samples
            obj.setTimeBase();
            [obj.status.runBlock] = obj.runBlock(obj.BlockGroupObj,0);

            if ~get(obj.viewObj.ControlButtons.StopButton,'Value')
                % Obtain block data, unit: mV
                obj.BlockData = cell(10,1);
                [obj.BlockData{:}] = invoke(obj.BlockGroupObj,'getBlockData',0,0,1,0);
                obj.numSamples = obj.BlockData{1};
                % Process the collected data
                obj.processCollectedData();
                obj.notify('notifier_DataCollectedSuccessfully');
            end

            % Stop the device
            [obj.status.stop] = invoke(obj.ps4000aDeviceObj,'ps4000aStop');
        end

        % Modified 'runBlock()' function from `picotech_ps4000a_generic.mdd` file
        % Supporting user interruptes the trigger-waiting progress
        function [status,timeIndisposedMs] = runBlock(obj,DeviceObj,segmentIndex)
            % For group functions, OBJ is the group object. For base device functions, OBJ is the device object.
            deviceObj = get(DeviceObj, 'Parent');
            deviceObj.DriverData.displayOutput = PicoConstants.FALSE;
            timeIndisposedMs = 0;   % Initialise to pass as pointer.
            lpReady = [];           % Set to NULL - Callback function not used.
            pParameter = [];        % Set to NULL - Callback function not used.

            unitHandle = deviceObj.DriverData.unitHandle;
            timebaseIdx = deviceObj.DriverData.timebase;
            preTriggerSamples = deviceObj.DriverData.numPreTriggerSamples;
            postTriggerSamples = deviceObj.DriverData.numPostTriggerSamples;

            if (deviceObj.DriverData.displayOutput == PicoConstants.TRUE)
                fprintf('runBlock:- Collecting block of data:\n\tTimebase: %u\n\tPre-trigger samples: %u\n\tPost-trigger samples: %u\n', ...
                    timebaseIdx, preTriggerSamples, postTriggerSamples);
            end

            [runBlockStatus, timeIndisposedMs] = calllib('ps4000a', 'ps4000aRunBlock', ...
                unitHandle, preTriggerSamples, postTriggerSamples, timebaseIdx, timeIndisposedMs, segmentIndex, lpReady, pParameter);

            if(runBlockStatus ~= PicoStatus.PICO_OK)
                error('runBlock:- Error in ps4000aRunBlock call - code %d', runBlockStatus);
            end

            if (deviceObj.DriverData.displayOutput == PicoConstants.TRUE)
                fprintf('runBlock: Waiting for device to become ready...\n');
            end

            ready = 0; % Initialise value for pointer

            while (ready == 0 && get(obj.viewObj.ControlButtons.StopButton,'Value') == 0)
                pause(1e-5)
                if get(obj.viewObj.ControlButtons.StopButton,'Value') == 1
                    disp('STOP button clicked - aborting data collection.')
                    status = PicoStatus.PICO_OK;
                    return
                end
                [readyStatus, ready] = calllib('ps4000a', 'ps4000aIsReady',unitHandle, ready);
                if(readyStatus == PicoStatus.PICO_OK || readyStatus == PicoStatus.PICO_BUSY)
                    % Do nothing
                else
                    error('runBlock: Error in ps4000aIsReady call - code %d', readyStatus);
                end
            end

            % Other conditions would have been captured.
            if (get(obj.viewObj.ControlButtons.StopButton,'Value')==PicoStatus.PICO_OK ...
                    && runBlockStatus == PicoStatus.PICO_OK && readyStatus == PicoStatus.PICO_OK)
                status = PicoStatus.PICO_OK;
                if (deviceObj.DriverData.displayOutput == PicoConstants.TRUE)
                    fprintf('runBlock: Device ready.\n\n');
                end
            else
                if(runBlockStatus ~= PicoStatus.PICO_OK)
                    error('runBlock:- ps4000aRunBlock error code: %d. Please refer to the PicoStatus.m file.', runBlockStatus);
                else
                    error('runBlock:- ps4000aIsReady error code: %d. Please refer to the PicoStatus.m file.', readyStatus);
                end
            end
        end

        % Process and save collected data
        function processCollectedData(obj,~,~)
            % Process
            timeNs = double(obj.timeIntervalNanoSeconds) * double(0:(obj.numSamples-1)); % unit: nanosecond
            obj.timeMs = timeNs / 1e6; % convert to millisecond

            ChannelData = obj.BlockData;
            ChannelData(1:2) = [];
            hasDataIdx = ~cellfun(@isempty,ChannelData);
            CollectedData = ChannelData(hasDataIdx); %#ok
            obj.hasDataChannels = obj.AvailableChannels(hasDataIdx);

            for i = 1:numel(obj.hasDataChannels)
                ChannelName = obj.hasDataChannels(i);
                eval(strcat("obj.hasDataStruct.",ChannelName,".Data=CollectedData{i};"));
                eval(strcat("obj.hasDataStruct.",ChannelName,".Range","=obj.ChannelRanges.(ChannelName);"));
                eval(strcat("obj.hasDataStruct.",ChannelName,".Unit","=obj.ChannelUnits.(ChannelName);"));
            end
            obj.notify('notifier_DataCollectedSuccessfully');
        end

        % Save data function
        function callback_saveData(obj,~,~)
            for i = 1:numel(obj.hasDataChannels)
                ChannelName = obj.hasDataChannels(i);
                eval(strcat(ChannelName,"=obj.hasDataStruct.",ChannelName));
            end

            time = obj.timeMs';%#ok
            UnitTime = 'ms';   %#ok

            FileBaseName = string(datetime("now","Format","uuuuMMdd-"));
            ExistedMATFiles = dir(fullfile(pwd,FileBaseName+"*.mat"));
            if ~isempty(ExistedMATFiles)
                ExistedMATFiles = ExistedMATFiles(end).name;
                maxIdx = str2double(ExistedMATFiles(10:end-4));
                idx = maxIdx+1;
            else
                idx = 1;
            end

            CompleteFileName = FileBaseName+sprintf("%04s",num2str(idx));
            SavedVariableName = num2cell(obj.hasDataChannels)';
            SavedVariableName{numel(SavedVariableName)+1} = "time";
            SavedVariableName{numel(SavedVariableName)+1} = "UnitTime";
            
            % Save data
            savingProgressDialog = uiprogressdlg(obj.viewObj.fig, ...
                'Title','Saving data...','Indeterminate','on');
            drawnow;
            uisave(SavedVariableName,CompleteFileName);
            close(savingProgressDialog);
        end

        % Load .mat data file
        function callback_loadMatDataFile(obj,~,~)
            loadingProgressDialog = uiprogressdlg(obj.viewObj.fig, ...
                'Title','Loading data...','Indeterminate','on');
            drawnow;
            file = uigetfile(".mat");
            close(loadingProgressDialog);

            if isequal(file,0)
                disp('User selected Cancel');
            else
                % Load data
                s = load(file);
                obj.viewObj.clearDataAndAxes();
                VariableName = fieldnames(s);
                obj.timeMs = s.time;
                for i = 1:numel(obj.AvailableChannels)
                    ChannelName = obj.AvailableChannels(i);
                    if any(strcmp(ChannelName,VariableName))
                        obj.hasDataChannels = [obj.hasDataChannels,ChannelName];
                        obj.hasDataStruct.(ChannelName).Data = s.(ChannelName).Data;
                        obj.hasDataStruct.(ChannelName).Range = s.(ChannelName).Range;
                        obj.hasDataStruct.(ChannelName).Unit = s.(ChannelName).Unit;
                    end
                end
                obj.notify('notifier_loadDataSuccessfully');
            end
        end
    end

    methods % notifiers
        function callback_changeChannelSettings(obj,~,~)
            obj.callback_updateChannelSettings();
        end

        function callback_changeChannelRange(obj,~,~)
            obj.callback_updateChannelSettings();
            obj.notify('notifier_updateChannelRangeSettings');% Notify View to update axes y-range
        end

        function callback_clearAxes(obj,~,~)
            obj.notify('notifier_clearAxes');
        end

        function callback_updateEnableCheckBox(obj,~,~)
            obj.notify('notifier_updateChannelEnable');
            obj.callback_updateChannelSettings();
        end

        function callback_stopCaptureData(obj,~,~)
            obj.notify('notifier_collectionAborting');
        end

        function callback_updateAutoTriggerEnable(obj,~,~)
            obj.notify('notifier_updateAutoTrigger');
            obj.callback_updateTriggerSettings();
        end

    end
end

