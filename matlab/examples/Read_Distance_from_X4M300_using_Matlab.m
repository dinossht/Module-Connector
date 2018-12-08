% This example demonstrate how you can set your own presence detection treshold based on
% the movinglist output. This script streams slow and fast movement and compare the firmware
% threshold for presence detection to a custom threshold. The script might
% take a minuite or two to initialize the sensor befor it start streaming.
%
% To complete the following example you need:
% - An X4M300 module
% - The ModuleConnector library
% - MATLAB


%add paths

addpath('/home/dino/Programs/Module-Connector/matlab/');
addpath('/home/dino/Programs/Module-Connector/include/');
addpath('/home/dino/Programs/Module-Connector/lib/');


clc
clear

%select comport
COMPORT = '/dev/ttyACM0';

% load library
Lib = ModuleConnector.Library;

% Moduleconnector object and X4M300 interface
mc = ModuleConnector.ModuleConnector(COMPORT,0);

X4M300 = mc.get_x4m300;
X4M300.set_sensor_mode('stop');

%empty buffer
while X4M300.peek_message_presence_movinglist > 0
X4M300.read_message_presence_movinglist();
end

%User configurations:
movinglist_output=hex2dec('723bfa1f'); %movinglist output
profile=hex2dec('014d4ab8'); %Presence profile

X4M300.load_profile(profile);
X4M300.set_output_control(movinglist_output, 1);

%set detection zone
start=0.4;
stop=4;
X4M300.set_detection_zone(start , stop);

%Start sensor
X4M300.set_sensor_mode('run');



%% Figure config
states = {'No Presence'; 'Presence'; 'Initializing'};
fh = figure(1);
clf(1);


%Configuring subplots for Movement vectors
subplot(3,2,[1,2]);
ph_mvs = plot(NaN,NaN);
th_mvs = title('');
grid on;
xlim([start, stop]);
ylim([0,100]);
ylabel('Movement slow')

subplot(3,2,[3,4]);
ph_mvf = plot(NaN,NaN);
th_mvf = title('');
grid on;
xlim([start, stop]);
ylim([0,100]);
ylabel('Movement fast')

%Configuring subplots for Presence state plots
p_ax1=subplot(3,2,5);
ph_ps1 = plot(NaN,NaN);
h1 = animatedline;
title('Presence State');
grid on;
ylim([0,2]);
set(gca,'ytick',[0:2],'yticklabel',states);
set(gca,'XTickLabel',[]);

p_ax2=subplot(3,2,6);
ph_ps2 = plot(NaN,NaN);
h2 = animatedline;
title('Custom Presence State');
grid on;
ylim([0,2]);
set(gca,'ytick',[0:2],'yticklabel',states);
set(gca,'XTickLabel',[]);

%% Data Visualization
[p_message, status]=X4M300.read_message_presence_movinglist();

%Wait for the module to initialize
while p_message.presence_state == 2
[p_message, status]=X4M300.read_message_presence_movinglist();
end

%generate range axis using only active cells
range_count=p_message.movementIntervalCount;
range_axis=linspace(start,stop, range_count);

%set xaxis to the range vector generated
ph_mvs.XData = range_axis;
ph_mvf.XData = range_axis;

%custom presence state variable
ps_custom=0;

startTime = datetime('now');
while ishandle(fh)

%read presence movinglist data from sensor
[p_message, status]=X4M300.read_message_presence_movinglist();
%firmware presence state
ps=p_message.presence_state;

distance=p_message.detectionDistance %%%%%%%%%%%%
%update moving slow/fast vectors
mv_s=p_message.movementSlowItem;
mv_f=p_message.movementFastItem;


%Configure own present state here:
if (sum(mv_f(1:range_count))>0)
ps_custom=1;
else
ps_custom=0;
end

%stream movementdata
ph_mvs.YData = mv_s(1:range_count);
ph_mvf.YData = mv_f(1:range_count);

%aquire current time
t = datetime('now') - startTime;

%stream presence state
addpoints(h1,datenum(t),ps)
p_ax1.XLim = datenum([t-seconds(90) t]);


%stream custom presence state
addpoints(h2,datenum(t),ps_custom)
p_ax2.XLim = datenum([t-seconds(90) t]);

datetick('x','keeplimits')
drawnow;

end
%stop and reset sensor
X4M300.set_sensor_mode('stop');
X4M300.module_reset();

% Clean up.
clear mc;
clear X4M300;
Lib.unloadlib;
clear Lib; 