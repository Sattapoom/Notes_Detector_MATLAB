classdef Notes_Detector_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        NotesDetectorKMUTNBUIFigure  matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        TimezoomingxSpinner          matlab.ui.control.Spinner
        TimezoomingxSpinnerLabel     matlab.ui.control.Label
        UnsupportedLabel             matlab.ui.control.Label
        msLabel                      matlab.ui.control.Label
        HzLabel                      matlab.ui.control.Label
        RecordlengthSlider           matlab.ui.control.Slider
        RecordlengthLabel            matlab.ui.control.Label
        SamplerateSlider             matlab.ui.control.Slider
        SamplerateLabel              matlab.ui.control.Label
        AppName                      matlab.ui.control.Label
        InputdeviceLabel             matlab.ui.control.Label
        FrequencyLabel               matlab.ui.control.Label
        NoteLabel                    matlab.ui.control.Label
        NoteSCALE                    matlab.ui.control.SemicircularGauge
        InputdeviceDropDown          matlab.ui.control.DropDown
        RecordButton                 matlab.ui.control.Button
        TDSLabel                     matlab.ui.control.Label
        FDSLabel                     matlab.ui.control.Label
        TDSAxes                      matlab.ui.control.UIAxes
        FDSAxes                      matlab.ui.control.UIAxes
    end


    properties (Access = private)

        frequencies = [16.35 17.32 18.35 19.45 20.6 21.83 23.12 24.5 25.96 27.5 29.14 30.87 32.7 34.65 36.71 38.89 41.2 43.65 46.25 49 51.91 55 58.27 61.74 65.41 69.3 73.42 77.78 82.41 87.31 92.5 98 103.83 110 116.54 123.47 130.81 138.59 146.83 155.56 164.81 174.61 185 196 207.65 220 233.08 246.94 261.63 277.18 293.66 311.13 329.63 349.23 369.99 392 415.3 440 466.16 493.88 523.25 554.37 587.33 622.25 659.25 698.46 739.99 783.99 830.61 880 932.33 987.77 1046.5 1108.73 1174.66 1244.51 1318.51 1396.91 1479.98 1567.98 1661.22 1760 1864.66 1975.53 2093 2217.46 2349.32 2489.02 2637.02 2793.83 2959.96 3135.96 3322.44 3520 3729.31 3951.07 4186.01 4434.92 4698.63 4978.03 5274.04 5587.65 5919.91 6271.93 6644.88 7040 7458.62 7902.13];
        notes = ["C0" "Db0" "D0" "Eb0" "E0" "F0" "Gb0" "G0" "Ab0" "A0" "Bb0" "B0" "C1" "Db1" "D1" "Eb1" "E1" "F1" "Gb1" "G1" "Ab1" "A1" "Bb1" "B1" "C2" "Db2" "D2" "Eb2" "E2" "F2" "Gb2" "G2" "Ab2" "A2" "Bb2" "B2" "C3" "Db3" "D3" "Eb3" "E3" "F3" "Gb3" "G3" "Ab3" "A3" "Bb3" "B3" "C4" "Db4" "D4" "Eb4" "E4" "F4" "Gb4" "G4" "Ab4" "A4" "Bb4" "B4" "C5" "Db5" "D5" "Eb5" "E5" "F5" "Gb5" "G5" "Ab5" "A5" "Bb5" "B5" "C6" "Db6" "D6" "Eb6" "E6" "F6" "Gb6" "G6" "Ab6" "A6" "Bb6" "B6" "C7" "Db7" "D7" "Eb7" "E7" "F7" "Gb7" "G7" "Ab7" "A7" "Bb7" "B7" "C8" "Db8" "D8" "Eb8" "E8" "F8" "Gb8" "G8" "Ab8" "A8" "Bb8" "B8"];
        NoteIndex = 0;
        
        Arec = audiorecorder;
        plotPause = true;

        InputsInfo = audiodevinfo().input;
        TotolDevice = audiodevinfo(1);
        deviceID = -1;

        SamplingRate = 8000;
        RecordLength = 25

    end

    methods (Access = private)

        function plotAudio(app)

            while ~app.plotPause

                try
                    datalength = app.RecordLength/1000;

                    recordblocking(app.Arec, datalength);
    
                    audio = getaudiodata(app.Arec);
    
                    Tscale = linspace(0,datalength,length(audio));
    
                    plot(app.TDSAxes,Tscale,audio);
    
                    Fs = app.Arec.SampleRate;               % Sampling frequency
                    L = length(audio);                      % Length of signal
    
                    Y = fft(audio);
    
                    P2 = abs(Y/L);
                    P1 = P2(1:L/2+1);
                    P1(2:end-1) = 2*P1(2:end-1);
    
                    f = Fs*(0:(L/2))/L;
                    plot(app.FDSAxes,f,P1);
    
                    app.updateDetectedNote(f,P1);

                catch
                    beep;
                    app.stopPlot();
                end

            end
        end

        function updateDetectedNote(app,freqes,ampts)

            [~,index] = max(ampts);
            maxFreq = freqes(index);

            A = repmat(app.frequencies,[1 length(maxFreq)]);
            [~,closestIndex] = min(abs(A-maxFreq'));
            app.NoteIndex = closestIndex;

            app.NoteLabel.Text = app.notes(app.NoteIndex);
            app.NoteSCALE.Value = mod(app.NoteIndex-1,12);
            app.FrequencyLabel.Text = string(maxFreq)+" Hz";
            
            xline(app.FDSAxes,maxFreq,'--',string(maxFreq)+" Hz")

        end

        
        function stopPlot(app)

            app.RecordButton.Text="START RECORD";
            app.RecordButton.BackgroundColor="#ffffff";
            app.plotPause = true;

        end
        
        function setAudiorecorder(app)
            app.stopPlot();
            if audiodevinfo(1,app.deviceID,app.SamplingRate,8,1)
                clear app.Arec;
                app.Arec = audiorecorder(app.SamplingRate,8,1,app.deviceID);
                set(app.UnsupportedLabel, 'Visible', 'off');
            else
                beep;
                set(app.UnsupportedLabel, 'Visible', 'on');
                app.InputdeviceDropDown.Value = "Default";
                app.Arec = audiorecorder;
            end
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: RecordButton
        function RecordButtonPushed(app, event)
            if app.RecordButton.Text == "START RECORD"
                app.RecordButton.Text="RECORDING...";
                app.RecordButton.BackgroundColor="#f0f0f0";

                app.plotPause = false;
                app.plotAudio();

            elseif app.RecordButton.Text == "RECORDING..."
                app.stopPlot();
            end
        end

        % Value changed function: InputdeviceDropDown
        function InputdeviceDropDownValueChanged(app, event)
            value = app.InputdeviceDropDown.Value;

            app.deviceID = -1;

            if value ~= "Default"            
                for i = 1:app.TotolDevice

                    if strcmp(app.InputsInfo(i).Name,value)
                        app.deviceID = app.InputsInfo(i).ID;
                        break;
                    end

                end    
            end

            app.setAudiorecorder()
            

        end

        % Drop down opening function: InputdeviceDropDown
        function InputdeviceDropDownOpening(app, event)
            clear app.InputsInfo app.TotolDevice
            audiodevreset;
            app.InputsInfo = audiodevinfo().input;
            app.TotolDevice = audiodevinfo(1);
            
            devicelist = {'Default'};

            for c = 1:app.TotolDevice
                devicelist{1,c+1} = app.InputsInfo(c).Name;
            end

            app.InputdeviceDropDown.Items = devicelist;

            app.stopPlot();
        end

        % Value changed function: SamplerateSlider
        function SamplerateSliderValueChanged(app, event)
            slider_value = round(app.SamplerateSlider.Value);
            set(app.SamplerateSlider, 'Value', slider_value);

            SR_list = [8000, 11025, 22050, 44100, 48000, 96000, 192000];
            app.SamplingRate = SR_list(slider_value + 1);
            
            app.setAudiorecorder();
        end

        % Value changed function: RecordlengthSlider
        function RecordlengthSliderValueChanged(app, event)
            value = app.RecordlengthSlider.Value;
            app.RecordLength = value;
            
            sec = value/1000;
            set(app.TDSAxes, 'XLim', [0, sec]);
            set(app.TDSAxes, 'XTick', [0, sec]);
            set(app.TDSAxes, 'XTickLabel', string(value));
            set(app.TimezoomingxSpinner, 'Value', 1)
        end

        % Value changed function: TimezoomingxSpinner
        function TimezoomingxSpinnerValueChanged(app, event)
            value = app.TimezoomingxSpinner.Value;
            set(app.TDSAxes, 'XLim', [0, (app.RecordLength/1000)/value]);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create NotesDetectorKMUTNBUIFigure and hide until all components are created
            app.NotesDetectorKMUTNBUIFigure = uifigure('Visible', 'off');
            app.NotesDetectorKMUTNBUIFigure.Position = [100 100 960 720];
            app.NotesDetectorKMUTNBUIFigure.Name = 'Notes Detector KMUTNB';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.NotesDetectorKMUTNBUIFigure);
            app.GridLayout.ColumnWidth = {'1x', 0, '1x', '0.5x', '1.3x', '0.2x'};
            app.GridLayout.RowHeight = {'1x', '0.75x', '0.75x', '0.5x', '0.5x', 0, '0.5x', '1x', '1x', '1x', '1x', '0.5x', '0.5x'};
            app.GridLayout.BackgroundColor = [0.9569 0.9451 0.8784];

            % Create FDSAxes
            app.FDSAxes = uiaxes(app.GridLayout);
            xlabel(app.FDSAxes, 'Frequency')
            ylabel(app.FDSAxes, 'Normalized Amplitude')
            app.FDSAxes.Toolbar.Visible = 'off';
            app.FDSAxes.XColor = [0.0784 0.2863 0.3333];
            app.FDSAxes.YColor = [0.0784 0.2863 0.3333];
            app.FDSAxes.HandleVisibility = 'off';
            app.FDSAxes.Layout.Row = [8 12];
            app.FDSAxes.Layout.Column = [4 6];

            % Create TDSAxes
            app.TDSAxes = uiaxes(app.GridLayout);
            xlabel(app.TDSAxes, 'time (ms)')
            ylabel(app.TDSAxes, 'Amplitude')
            app.TDSAxes.Toolbar.Visible = 'off';
            app.TDSAxes.XLim = [0 0.025];
            app.TDSAxes.TickLength = [0.01 0.01];
            app.TDSAxes.XColor = [0.0784 0.2902 0.3294];
            app.TDSAxes.XTick = [0 0.025];
            app.TDSAxes.XTickLabel = {'0'; '25'};
            app.TDSAxes.YColor = [0.0784 0.2863 0.3333];
            app.TDSAxes.YTickLabel = {'0'; '0.2'; '0.4'; '0.6'; '0.8'; '1'};
            app.TDSAxes.YMinorTick = 'on';
            app.TDSAxes.TickDir = 'in';
            app.TDSAxes.HandleVisibility = 'off';
            app.TDSAxes.Layout.Row = [8 12];
            app.TDSAxes.Layout.Column = [1 3];

            % Create FDSLabel
            app.FDSLabel = uilabel(app.GridLayout);
            app.FDSLabel.HorizontalAlignment = 'center';
            app.FDSLabel.VerticalAlignment = 'bottom';
            app.FDSLabel.FontSize = 18;
            app.FDSLabel.FontWeight = 'bold';
            app.FDSLabel.FontColor = [0.0784 0.2863 0.3333];
            app.FDSLabel.Layout.Row = 7;
            app.FDSLabel.Layout.Column = [4 6];
            app.FDSLabel.Text = 'Frequency Domain Signal';

            % Create TDSLabel
            app.TDSLabel = uilabel(app.GridLayout);
            app.TDSLabel.HorizontalAlignment = 'center';
            app.TDSLabel.VerticalAlignment = 'bottom';
            app.TDSLabel.FontSize = 18;
            app.TDSLabel.FontWeight = 'bold';
            app.TDSLabel.FontColor = [0.0784 0.2863 0.3333];
            app.TDSLabel.Layout.Row = 7;
            app.TDSLabel.Layout.Column = [1 3];
            app.TDSLabel.Text = 'Time Domain Signal';

            % Create RecordButton
            app.RecordButton = uibutton(app.GridLayout, 'push');
            app.RecordButton.ButtonPushedFcn = createCallbackFcn(app, @RecordButtonPushed, true);
            app.RecordButton.BackgroundColor = [1 1 1];
            app.RecordButton.FontSize = 14;
            app.RecordButton.FontWeight = 'bold';
            app.RecordButton.FontColor = [0.9451 0.298 0.2196];
            app.RecordButton.Layout.Row = 5;
            app.RecordButton.Layout.Column = [4 6];
            app.RecordButton.Text = 'START RECORD';

            % Create InputdeviceDropDown
            app.InputdeviceDropDown = uidropdown(app.GridLayout);
            app.InputdeviceDropDown.Items = {'Default'};
            app.InputdeviceDropDown.DropDownOpeningFcn = createCallbackFcn(app, @InputdeviceDropDownOpening, true);
            app.InputdeviceDropDown.ValueChangedFcn = createCallbackFcn(app, @InputdeviceDropDownValueChanged, true);
            app.InputdeviceDropDown.FontWeight = 'bold';
            app.InputdeviceDropDown.FontColor = [0.0784 0.2863 0.3333];
            app.InputdeviceDropDown.BackgroundColor = [1 1 1];
            app.InputdeviceDropDown.Layout.Row = 4;
            app.InputdeviceDropDown.Layout.Column = [5 6];
            app.InputdeviceDropDown.Value = 'Default';

            % Create NoteSCALE
            app.NoteSCALE = uigauge(app.GridLayout, 'semicircular');
            app.NoteSCALE.Limits = [0 11];
            app.NoteSCALE.MajorTicks = [0 2 4 5 7 9 11];
            app.NoteSCALE.MajorTickLabels = {'C', 'D', 'E', 'F', 'G', 'A', 'B'};
            app.NoteSCALE.MinorTicks = [1 3 6 8 10];
            app.NoteSCALE.FontSize = 24;
            app.NoteSCALE.FontWeight = 'bold';
            app.NoteSCALE.FontColor = [0.0784 0.2863 0.3333];
            app.NoteSCALE.Layout.Row = [1 5];
            app.NoteSCALE.Layout.Column = [1 3];

            % Create NoteLabel
            app.NoteLabel = uilabel(app.GridLayout);
            app.NoteLabel.HorizontalAlignment = 'center';
            app.NoteLabel.VerticalAlignment = 'top';
            app.NoteLabel.FontSize = 24;
            app.NoteLabel.FontWeight = 'bold';
            app.NoteLabel.FontColor = [0.9451 0.298 0.2196];
            app.NoteLabel.Layout.Row = 3;
            app.NoteLabel.Layout.Column = [1 3];
            app.NoteLabel.Text = 'NOTE';

            % Create FrequencyLabel
            app.FrequencyLabel = uilabel(app.GridLayout);
            app.FrequencyLabel.HorizontalAlignment = 'center';
            app.FrequencyLabel.VerticalAlignment = 'top';
            app.FrequencyLabel.FontSize = 24;
            app.FrequencyLabel.FontWeight = 'bold';
            app.FrequencyLabel.FontColor = [0.9451 0.298 0.2196];
            app.FrequencyLabel.Layout.Row = 4;
            app.FrequencyLabel.Layout.Column = [1 3];
            app.FrequencyLabel.Text = '0 Hz';

            % Create InputdeviceLabel
            app.InputdeviceLabel = uilabel(app.GridLayout);
            app.InputdeviceLabel.HorizontalAlignment = 'right';
            app.InputdeviceLabel.VerticalAlignment = 'bottom';
            app.InputdeviceLabel.FontSize = 14;
            app.InputdeviceLabel.FontWeight = 'bold';
            app.InputdeviceLabel.FontColor = [0.0784 0.2863 0.3333];
            app.InputdeviceLabel.Layout.Row = 4;
            app.InputdeviceLabel.Layout.Column = 4;
            app.InputdeviceLabel.Text = 'Input device :';

            % Create AppName
            app.AppName = uilabel(app.GridLayout);
            app.AppName.HorizontalAlignment = 'center';
            app.AppName.FontSize = 36;
            app.AppName.FontWeight = 'bold';
            app.AppName.FontAngle = 'italic';
            app.AppName.FontColor = [0.9451 0.298 0.2196];
            app.AppName.Layout.Row = 1;
            app.AppName.Layout.Column = [4 6];
            app.AppName.Text = 'Notes Detector';

            % Create SamplerateLabel
            app.SamplerateLabel = uilabel(app.GridLayout);
            app.SamplerateLabel.HorizontalAlignment = 'right';
            app.SamplerateLabel.VerticalAlignment = 'bottom';
            app.SamplerateLabel.FontSize = 14;
            app.SamplerateLabel.FontWeight = 'bold';
            app.SamplerateLabel.FontColor = [0.0784 0.2863 0.3333];
            app.SamplerateLabel.Layout.Row = 2;
            app.SamplerateLabel.Layout.Column = 4;
            app.SamplerateLabel.Text = 'Sample rate :';

            % Create SamplerateSlider
            app.SamplerateSlider = uislider(app.GridLayout);
            app.SamplerateSlider.Limits = [0 6];
            app.SamplerateSlider.MajorTicks = [0 1 2 3 4 5 6];
            app.SamplerateSlider.MajorTickLabels = {'8000', '11025', '22050', '44100', '48000', '96000', '192000'};
            app.SamplerateSlider.ValueChangedFcn = createCallbackFcn(app, @SamplerateSliderValueChanged, true);
            app.SamplerateSlider.MinorTicks = [];
            app.SamplerateSlider.Layout.Row = 2;
            app.SamplerateSlider.Layout.Column = 5;
            app.SamplerateSlider.FontWeight = 'bold';
            app.SamplerateSlider.FontColor = [0.0784 0.2863 0.3333];

            % Create RecordlengthLabel
            app.RecordlengthLabel = uilabel(app.GridLayout);
            app.RecordlengthLabel.HorizontalAlignment = 'right';
            app.RecordlengthLabel.VerticalAlignment = 'bottom';
            app.RecordlengthLabel.FontSize = 14;
            app.RecordlengthLabel.FontWeight = 'bold';
            app.RecordlengthLabel.FontColor = [0.0784 0.2863 0.3333];
            app.RecordlengthLabel.Layout.Row = 3;
            app.RecordlengthLabel.Layout.Column = 4;
            app.RecordlengthLabel.Text = 'Record length :';

            % Create RecordlengthSlider
            app.RecordlengthSlider = uislider(app.GridLayout);
            app.RecordlengthSlider.Limits = [25 500];
            app.RecordlengthSlider.ValueChangedFcn = createCallbackFcn(app, @RecordlengthSliderValueChanged, true);
            app.RecordlengthSlider.Layout.Row = 3;
            app.RecordlengthSlider.Layout.Column = 5;
            app.RecordlengthSlider.FontWeight = 'bold';
            app.RecordlengthSlider.FontColor = [0.0784 0.2863 0.3333];
            app.RecordlengthSlider.Value = 25;

            % Create HzLabel
            app.HzLabel = uilabel(app.GridLayout);
            app.HzLabel.VerticalAlignment = 'bottom';
            app.HzLabel.FontSize = 14;
            app.HzLabel.FontWeight = 'bold';
            app.HzLabel.FontColor = [0.0784 0.2863 0.3333];
            app.HzLabel.Layout.Row = 2;
            app.HzLabel.Layout.Column = 6;
            app.HzLabel.Text = 'Hz.';

            % Create msLabel
            app.msLabel = uilabel(app.GridLayout);
            app.msLabel.VerticalAlignment = 'bottom';
            app.msLabel.FontSize = 14;
            app.msLabel.FontWeight = 'bold';
            app.msLabel.FontColor = [0.0784 0.2863 0.3333];
            app.msLabel.Layout.Row = 3;
            app.msLabel.Layout.Column = 6;
            app.msLabel.Text = 'ms.';

            % Create UnsupportedLabel
            app.UnsupportedLabel = uilabel(app.GridLayout);
            app.UnsupportedLabel.HorizontalAlignment = 'center';
            app.UnsupportedLabel.VerticalAlignment = 'top';
            app.UnsupportedLabel.FontSize = 14;
            app.UnsupportedLabel.FontWeight = 'bold';
            app.UnsupportedLabel.FontColor = [0.9451 0.298 0.2196];
            app.UnsupportedLabel.Visible = 'off';
            app.UnsupportedLabel.Layout.Row = 2;
            app.UnsupportedLabel.Layout.Column = 4;
            app.UnsupportedLabel.Text = '** Unsupported.';

            % Create TimezoomingxSpinnerLabel
            app.TimezoomingxSpinnerLabel = uilabel(app.GridLayout);
            app.TimezoomingxSpinnerLabel.HorizontalAlignment = 'right';
            app.TimezoomingxSpinnerLabel.FontSize = 14;
            app.TimezoomingxSpinnerLabel.FontWeight = 'bold';
            app.TimezoomingxSpinnerLabel.FontColor = [0.0784 0.2863 0.3333];
            app.TimezoomingxSpinnerLabel.Layout.Row = 13;
            app.TimezoomingxSpinnerLabel.Layout.Column = 1;
            app.TimezoomingxSpinnerLabel.Text = 'Time zooming x';

            % Create TimezoomingxSpinner
            app.TimezoomingxSpinner = uispinner(app.GridLayout);
            app.TimezoomingxSpinner.Limits = [1 100];
            app.TimezoomingxSpinner.ValueChangedFcn = createCallbackFcn(app, @TimezoomingxSpinnerValueChanged, true);
            app.TimezoomingxSpinner.Layout.Row = 13;
            app.TimezoomingxSpinner.Layout.Column = [2 3];
            app.TimezoomingxSpinner.Value = 1;

            % Show the figure after all components are created
            app.NotesDetectorKMUTNBUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Notes_Detector_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.NotesDetectorKMUTNBUIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.NotesDetectorKMUTNBUIFigure)
        end
    end
end