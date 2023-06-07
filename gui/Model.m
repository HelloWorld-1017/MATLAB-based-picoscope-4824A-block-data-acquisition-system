classdef Model < handle
    properties
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
        ChannelSettings;
        ConnectionState = "closed";
        stopFlag = 0;
    end

    properties(Hidden)
        AutoTriggerSetting;
        TriggerChannelSetting;
        TriggerThresholdSetting;
        SimpleTriggerDirectionSetting;
        PreTriggerSetting;
        PostTriggerSetting;
        ChannelUnits;
        ChannelRanges;
    end

    events
        notifier_DeviceConnectionStateChanged;
        notifier_updateChannelSettings;
        notifier_updateChannelRangeSettings;
        notifier_updateAutoTrigger;
        notifier_updatePreTriggerSetting;
        notifier_updatePostTriggerSetting;
        notifier_updateChannelEnable;
        notifier_DataCollectedSuccessfully;
        notifier_loadDataSuccessfully;
        notifier_collectingData;
        notifier_collectionAborting;
        notifier_clearDataAndAxes;
        notifier_AxesNotEmpty;
    end

    methods
        % Constructor of 'Model' class
        function obj = Model()
            % Load configuration information. Setup paths and also load
            % struct and enumeration information. Enumeration values are
            % required for certain function calls.
            [obj.ps4000aStructs,obj.ps4000aEnuminfo] = ps4000aSetConfig(); % DO NOT EDIT THIS LINE.
        end
    end

    methods % callbacks for trigger settings
        function callback_updateAutoTriggerEnable(obj,~,~)
            obj.notify('notifier_updateAutoTrigger');
        end
        function callback_updateAutoTriggerSetting(obj,val)
            obj.AutoTriggerSetting = val;
        end
        function callback_updateTriggerChannelSetting(obj,val)
            obj.TriggerChannelSetting = val;
        end
        function callback_updateTriggerThresholdSetting(obj,val)
            obj.TriggerThresholdSetting = val;
        end
        function callback_updateSimpleTriggerDirectionSetting(obj,val)
            obj.SimpleTriggerDirectionSetting = val;
        end
        function callback_updatePreTriggerSetting(obj,val)
            obj.PreTriggerSetting = val;
            obj.notify('notifier_updatePreTriggerSetting');
        end
        function callback_updatePostTriggerSetting(obj,val)
            obj.PostTriggerSetting = val;
            obj.notify('notifier_updatePostTriggerSetting');
        end
        % Update trigger settings function
        function callback_updateTriggerSettings(obj)
            % Set simple trigger
            obj.RriggerGroupObj = get(obj.ps4000aDeviceObj,'Trigger');
            obj.RriggerGroupObj = obj.RriggerGroupObj(1);

            % Set the autoTriggerMs property
            set(obj.RriggerGroupObj,'autoTriggerMs',obj.AutoTriggerSetting);
            [obj.status.setSimpleTrigger] = invoke(obj.RriggerGroupObj,'setSimpleTrigger', ...
                obj.TriggerChannelSetting,...
                obj.TriggerThresholdSetting, ...
                obj.SimpleTriggerDirectionSetting);

            % Set block parameters and capture data
            obj.BlockGroupObj = get(obj.ps4000aDeviceObj, 'Block');
            obj.BlockGroupObj = obj.BlockGroupObj(1);

            set(obj.ps4000aDeviceObj,'numPreTriggerSamples',obj.PreTriggerSetting);
            set(obj.ps4000aDeviceObj,'numPostTriggerSamples',obj.PostTriggerSetting);

            disp('Update trigger settings!')
        end
    end

    methods % callbacks for channel settings
        function callback_updateChannelEnableCheckBox(obj,ChannelName,EnableVal)
            obj.ChannelSettings.(ChannelName).ChannelEnable = EnableVal;
            if strcmp(obj.ConnectionState,'open')
                obj.notify('notifier_updateChannelEnable');
            end
        end
        function callback_updateChannelCouplingSetting(obj,ChannelName,CouplingVal)
            obj.ChannelSettings.(ChannelName).Coupling = CouplingVal;
        end
        function callback_updateChannelRangeSetting(obj,ChannelName,RangeVal)
            obj.ChannelSettings.(ChannelName).Range = RangeVal;
            obj.notify('notifier_updateChannelRangeSettings');% Notify View to update axes y-range
        end
        function callback_updateChannelOffsetSetting(obj,ChannelName,OffsetVal)
            obj.ChannelSettings.(ChannelName).Offset = OffsetVal;
        end
        % Update channel settings function
        function callback_updateChannelSettings(obj,~,~)
            for i = 1:numel(obj.AvailableChannels)
                ChannelName = obj.AvailableChannels(i);
                [obj.status.setChannel.(ChannelName)] = invoke(obj.ps4000aDeviceObj, ...
                    'ps4000aSetChannel', ...
                    i-1, ...
                    obj.ChannelSettings.(ChannelName).ChannelEnable,...
                    obj.ChannelSettings.(ChannelName).Coupling,...
                    obj.ChannelSettings.(ChannelName).Range,...
                    obj.ChannelSettings.(ChannelName).Offset);
            end
            obj.obtainRangeAndUnit();
            disp("Update channel settings!")
        end
        % Obtain the range and unit of each channel
        function obtainRangeAndUnit(obj)
            for i = 1:numel(obj.AvailableChannels)
                ChannelName = obj.AvailableChannels(i);
                eval(strcat("[obj.ChannelRanges.",ChannelName,",obj.ChannelUnits.",ChannelName, ...
                    "] = invoke(obj.ps4000aDeviceObj,'getChannelInputRangeAndUnits',obj.ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_",ChannelName,");"));
            end
        end
    end

    methods % callbacks for connecting, disconnecting device, and closing app
        % callback_connectDevice, callback_disconnectDevice, callback_closeApp
        function callback_connectDevice(obj,~,~)
            % Create a device object. The serial number can be specified as
            % a second input parameter.
            obj.ps4000aDeviceObj = icdevice('picotech_ps4000a_generic.mdd','');

            % Connect device
            connect(obj.ps4000aDeviceObj);
            obj.ConnectionState = "open";
            obj.notify('notifier_DeviceConnectionStateChanged');
        end

        % Disconnect device function
        function callback_disconnectDevice(obj,~,~)
            disconnect(obj.ps4000aDeviceObj);
            obj.ConnectionState = "closed";
            obj.notify('notifier_DeviceConnectionStateChanged');% Notify View to update display state
        end

        % Overload the `CloseRequestFcn` function of the uifigure
        function callback_closeApp(obj,fig)
            selection = uiconfirm(fig,'Close the App?',...
                'Confirmation');
            switch selection
                case 'OK'
                    % Disconnect device
                    try
                        disconnect(obj.ps4000aDeviceObj);
                    catch
                    end
                    % Delete the GUI
                    delete(fig);
                case 'Cancel'
                    return
            end
        end
    end

    methods % functions for collecting data
        % Collect data function
        function callback_captureData(obj)
            % Update trigger and channels settings
            obj.callback_updateTriggerSettings();
            obj.callback_updateChannelSettings();

            obj.notify('notifier_collectingData');
            pause(0.001);

            % Verify timebase index and maximum number of samples
            obj.setTimeBase();
            [obj.status.runBlock] = obj.runBlock(obj.BlockGroupObj,0);

            if ~obj.stopFlag
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

        % Modified 'runBlock()' function from
        % `picotech_ps4000a_generic.mdd` file Supporting user interruptes
        % the trigger-waiting progress
        function [status,timeIndisposedMs] = runBlock(obj,DeviceObj,segmentIndex)
            % For group functions, OBJ is the group object. For base device
            % functions, OBJ is the device object.
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

            while (ready == 0 && obj.stopFlag == 0)
                pause(1e-5)
                if obj.stopFlag == 1
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
            if (obj.stopFlag==PicoStatus.PICO_OK ...
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

        % Stop capturing data
        function callback_stopCaptureData(obj,src,~)
            obj.stopFlag = src.Value;
            obj.notify('notifier_collectionAborting');
            obj.stopFlag = 0;
        end
    end

    methods % functions for saving, loading and clearing data
        % Save data function
        function callback_saveData(obj,fig)
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
            savingProgressDialog = uiprogressdlg(fig, ...
                'Title','Saving data...','Indeterminate','on');
            drawnow;
            uisave(SavedVariableName,CompleteFileName);
            close(savingProgressDialog);
        end

        % Load .mat data file
        function callback_loadMatDataFile(obj,fig,~)
            loadingProgressDialog = uiprogressdlg(fig, ...
                'Title','Loading data...','Indeterminate','on');
            drawnow;
            file = uigetfile(".mat");
            close(loadingProgressDialog);

            if isequal(file,0)
                disp('User selected Cancel');
            else
                % Load data
                s = load(file);
                obj.notify('notifier_clearDataAndAxes');
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

        % Clear data and axes
        function callback_clearAxesAndData(obj,~,~)
            obj.notify('notifier_clearDataAndAxes');
        end
    end
end