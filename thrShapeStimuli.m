clear;close;sca;
a_front = arduinoManager('port','/dev/ttyACM0');a_front.open;a_front.shield = 'old';
a_back  = arduinoManager('port','/dev/ttyACM1');a_back.open; a_back.shield  = 'new';
%Audio Manager
if ~exist('aM','var') || isempty(aM) || ~isa(aM,'audioManager')
	aM=audioManager;
end
aM.silentMode = false;
if ~aM.isSetup;	aM.setup; end
trialN          = 3;
tic

try
	Screen('Preference', 'SkipSyncTests', 0);
	PsychDefaultSetup(2);
	baseColor        = [1 1 1];
	screenid         = max(Screen('Screens'));
	[win, winRect]   = Screen('OpenWindow', screenid, baseColor);
	ifi              = Screen('GetFlipInterval', win);
	%-------------------

	% Subject's name input
	%drawTextNow(sM,'Please enter your subject name...')
	%Screen('DrawText',win,"Enter subject name:",20, 50,[0 255 0]);
	subject= input ("Enter subject name:",'s');
	nameExp=[subject,'-',date,'.mat'];

	% Enable alpha-blending
	Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
	% the coordinats of the 2 dots
% 	target_x_left   = winRect(3)/3;
% 	target_y        = winRect(4)/2;
% 	target_x_right  = winRect(3)*2/3;
	%%showTime        = 5;
%-----------------
	% initial the touchpanels
	choiceTouch     = 2;
	dev             = GetTouchDeviceIndices([], 1);
	info_front      = GetTouchDeviceInfo(dev(choiceTouch));
	% disp(info_front);
	info_back       = GetTouchDeviceInfo(dev(2));
% 	disp(info_back);
% 	RestrictKeysForKbCheck(KbName('ESCAPE'));

	taskType        ='competition';
	TouchQueueCreate(win, dev(choiceTouch ));
	TouchQueueStart(dev(choiceTouch ));
% 	TouchQueueCreate(win, dev(2));
% 	TouchQueueStart(dev(2));
	text_left       = 'front-side was touched';
	text_right      = 'back-side was touched';
	text_both       = 'we two both get reward';
	KbReleaseWait;
	KbQueueRelease;
	
	text='Please press ESCAPE to start experiment...';
	Screen('DrawText',win,text,20, 50,[0 255 0]);
	Screen('Flip', win);
	RestrictKeysForKbCheck(KbName('ESCAPE'));
	KbWait;
	corretTrials.front = 0;
	corretTrials.back  = 0 ;
	corretTrials.poly  = 0 ;
	reactiontime.front = zeros(trialN,1);
	reactiontime.back  = zeros(trialN,1);
	reactiontime.poly  = zeros(trialN,1); 
	pixlespdegree = 17.6; % head distance to monitor
	Num=3; %nimber of location around a big circle
	circleRadius=7; % the big circle's size
	% the coordinats of the 3 dots
	target_x_left   = winRect(3)/3;
	target_y        = winRect(4)/2;
	target_x_right  = winRect(3)*2/3;
	anglesDegLoc = linspace(0, 360, Num+1);
	anglesRadLoc = anglesDegLoc * (pi / 180);
	radiusLoc    = circleRadius*pixlespdegree;%%% the circle's radius
	[xCenter, yCenter] = RectCenter(winRect);
	% X and Y coordinates of the points defining out polygon, centred on the     获取这些点的坐标（以屏幕中心为中心点）
	% centre of the screen
	
	for i=1:trialN
		fprintf('\n===>>> Running Trial %i\n',i);
		reward_front  = 0;
		reward_back   = 0;
		reward_poly   = 0;
		touched_front = 0;
		touched_back  = 0;
		touched_poly  = 0;
		rewardNo      = 0;
		timeOut       = 4;

		numSides = 5;
		anglesDeg = linspace(0, 360, numSides + 1);
		anglesRad = anglesDeg * (pi / 180);
		radius    = 55; % the size of the ploy shape
		yPosVectorLoc = sin(anglesRadLoc) .* radiusLoc + 650;
		xPosVectorLoc = cos(anglesRadLoc) .* radiusLoc + 700;
		locIndex      = randperm(Num,3);
		squarePos     = [xPosVectorLoc(locIndex(1)),yPosVectorLoc(locIndex(1))]';
		circlePos     = [xPosVectorLoc(locIndex(2)),yPosVectorLoc(locIndex(2))]';
		diamonPos     = [xPosVectorLoc(locIndex(3)),yPosVectorLoc(locIndex(3))]';
		yPosVector    = sin(anglesRad) .* radius + diamonPos(2);
		xPosVector    = cos(anglesRad) .* radius + diamonPos(1);
		rectColor     = [0 0 255];
		% target location setting
		circlePosT(2)=circlePos(2);
		squarePosT(2)=squarePos(2);
		diamonPosT(2)=diamonPos(2);
		if choiceTouch==1
			circlePosT(1)=1920-circlePos(1);
			squarePosT(1)=1920-squarePos(1);
			diamonPosT(1)=1920-diamonPos(1);
		else
			circlePosT(1)=circlePos(1);
			squarePosT(1)=squarePos(1);
			diamonPosT(1)=diamonPos(1);
		end

		% Cue to tell PTB that the polygon is convex (concave polygons require much       告知PTB这个多边形是凸的
		isConvex = 1;
		tStart = GetSecs; % on the next frame
		TouchEventFlush(dev(choiceTouch));
		% 			TouchEventFlush(dev(2));
		TouchQueueStart(dev(choiceTouch));
		% 			TouchQueueStart(dev(2)); % flush should be placed before the start
		while tStart < (tStart + timeOut)
			Screen('DrawDots', win, circlePos,80,[125 125 0],[0,0],2);% Circle
			Screen('DrawDots', win, squarePos,80,[255 0 0]);         % square
			Screen('FillPoly', win, rectColor, [xPosVector; yPosVector]',isConvex); % poly
			Screen('Flip', win);
			%tStart

			% 			Process all currently pending touch events:
			q1=TouchEventAvail(dev(choiceTouch));
			% 			q2=TouchEventAvail(dev(2));
			while q1
				% Event Front:
				evt_front      = TouchEventGet(dev(choiceTouch), win);
				if  isempty(evt_front)
					X_front       = 0;
					Y_front       = 0;
					front.Pressed = 0;
				else
					X_front       = evt_front.MappedX; % if the event=0, you can not pass the results to the evt_front obj
					Y_front       = evt_front.MappedY;
					front.Pressed = evt_front.Pressed;
				end

				touched_circle    = check_touch_position(X_front,Y_front,circlePosT);
				touched_squre     = check_touch_position(X_front,Y_front,squarePosT);
				touched_diamon    = check_touch_position(X_front,Y_front,diamonPosT);

				if front.Pressed&&touched_circle
					% 					disp('front monkey touched,reward to front')
					textMonkey='front monkey touched,reward to front';			
					reward_front    = 1;
					Screen('FillRect', win, baseColor);
					Screen('Flip', win);
					corretTrials.front = corretTrials.front+1;
					tf=GetSecs-tStart;
					break;
				elseif front.Pressed&&touched_squre
					% 					disp('front monkey touched,reward to back')
					textMonkey='front monkey touched, but reward to back one';
					reward_back     = 1;
					Screen('FillRect', win, baseColor);
					Screen('Flip', win);
		%			corretTrials.front = corretTrials.front+1;
					corretTrials.back = corretTrials.back+1;
					tb=GetSecs-tStart;
					break;

				elseif front.Pressed&&touched_diamon
					% 					disp('front monkey touched,no reward')
					textMonkey='front monkey touched,both sides get reward';
					rewardNo        = 1;
					reward_poly   = 1; %%
					Screen('FillRect', win, baseColor);
					Screen('Flip', win);
			%		corretTrials.front = corretTrials.front+1; %%%
					corretTrials.poly = corretTrials.poly+1;%%
					tp=GetSecs-tStart;
					break;
					%
				end

				if GetSecs-tStart>5
					break;
				end
			end
			

			if reward_front
				TouchQueueStop(dev(choiceTouch));
				Screen('DrawText',win,textMonkey,1920/2,target_y,[255 0 0]);
				Screen('Flip', win);
				a_front.stepper(46);
				aM.beep(2000,0.1,0.1);
				WaitSecs(2)
				break;
			elseif reward_back
				TouchQueueStop(dev(choiceTouch));
				Screen('DrawText',win,textMonkey,1920/2,target_y,[255 0 0]);
				Screen('Flip', win);
				a_back.stepper(46)
				aM.beep(2000,0.1,0.1);
				WaitSecs(2)
				break;
			elseif rewardNo==1
				TouchQueueStop(dev(choiceTouch));
				Screen('DrawText',win,textMonkey,1920/2,target_y,[255 0 0]);
				Screen('Flip', win);
				a_back.stepper(46)
				a_front.stepper(46);
				aM.beep(2000,0.1,0.1);
				WaitSecs(2)
				break;
			end
		end
		WaitSecs(1)
		fprintf('\n===>>> Trial %i took %.4f seconds\n',i, GetSecs-tStart);
		toc
	end
	a_front.close;a_back.close;
		
	%% Saving experiment information and results in a file called Socialtask_SubjectX.mat (X is subject number)
	if  reward_front
		reactiontime.front(i,1) = tf;
		results.corretTrials.front = corretTrials.front;
		results.reactiontime.front = reactiontime.front;
	end

	if reward_back
		reactiontime.back(i,1) = tb;
		results.corretTrials.back = corretTrials.back;
		results.reactiontime.back = reactiontime.back;
	end

	if  reward_poly
		reactiontime.poly(i,1) = tp;
		results.corretTrials.poly = corretTrials.poly;
		results.reactiontime.poly = reactiontime.poly;
	end

		results.subject = subject;
		results.trialN = trialN;
		results.corretTrials= corretTrials;
		results.reactiontime = reactiontime;
		results.TotalTime = toc/60;
		%fout=sprintf('Socialtask_Subject%d.mat', subject);
		save(nameExp, 'results');
        
		%%========================================
	
		sca;
		KbReleaseWait;
catch
% 	a_front.close;a_back.close;
	sca;
	psychrethrow(psychlasterror);
end


function touched=check_touch_position(touch_x,touch_y,targetPos)
window=50;%pixle
target_x=targetPos(1);
target_y=targetPos(2);
touched=0;
if touch_x>target_x-window&&touch_x<target_x+window&&touch_y>target_y-window&&touch_y<target_y+window
	touched=1;
end
end














% clear;sca
% sM       = screenManager('backgroundColour', [0 0 0],'blend',true);
% sv       = sM.open;
% ms       = metaStimulus;
% myDisc1    = discStimulus('colour',[1 0 0],'size',2, 'sigma', 1);
% myDisc2    = discStimulus('colour',[0 1 0],'size',2, 'sigma', 1);
% myDisc3    = discStimulus('colour',[0 0 1],'size',2, 'sigma', 1);
% ms{1}      = myDisc1;
% ms{2}      = myDisc2;
% ms{3}      = myDisc3;
% % ms{4}      = fCross;
% setup(ms,sM);
% drawTextNow(sM,'Please enter your subject name...')
% locNum        = 8;
% pixlespdegree = 17.6;
% radius        = 10;
% locIndex      = randperm(locNum,3);
% center        = [960 540];
% [x,y]         = randPosition(center,locNum,radius,pixlespdegree);
% myDisc1.xPositionOut  = 0;
% myDisc1.yPositionOut  = 0;
% 
% myDisc2.xPositionOut  = -20;
% myDisc2.yPositionOut  = 0;
% % 
% myDisc3.xPositionOut  = 5;
% myDisc3.yPositionOut  = 0;
% 
% myDisc1.update;
% myDisc2.update;myDisc3.update;
% % mybox     = myDisc.mvRect;
% ms.draw;
% vbl       = sM.flip;
% pause(1)
% sM.drawBackground;
% sM.flip
% ms.reset
% % 
% function [xPosVectorLoc,yPosVectorLoc ]=randPosition(center,locNum,radius,pixlespdegree)
% anglesDegLoc = linspace(0, 360, locNum+1);
% anglesRadLoc = anglesDegLoc * (pi / 180);
% radiusLoc    = radius*pixlespdegree;
% % [xCenter, yCenter] = center;
% xCenter = center(1);yCenter = center(2);
% % X and Y coordinates of the points defining out polygon, centred on the     获取这些点的坐标（以屏幕中心为中心点）
% % centre of the screen
% yPosVectorLoc = sin(anglesRadLoc) .* radiusLoc + yCenter;
% xPosVectorLoc = cos(anglesRadLoc) .* radiusLoc + xCenter*3/2;
% end

% tMfront  = touchManager; % touch for front panel
% choice   = 2;
% tMfront.setup(sM);

% 
% sca;clear
% dev             = GetTouchDeviceIndices([], 1);
% info_front      = GetTouchDeviceInfo(dev(1));
% 
% 
% 
% pixlespdegree = 17.6;
% Num=8;
% Screen('Preference', 'SkipSyncTests', 0);
% PsychDefaultSetup(2);
% baseColor        = [1 1 1];
% screenid         = max(Screen('Screens'));
% [win, winRect]   = Screen('OpenWindow', screenid, baseColor);
% ifi              = Screen('GetFlipInterval', win);
% Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
% % the coordinats of the 2 dots
% target_x_left   = winRect(3)/3;
% target_y        = winRect(4)/2;
% target_x_right  = winRect(3)*2/3;
% anglesDegLoc = linspace(0, 360, Num+1);
% anglesRadLoc = anglesDegLoc * (pi / 180);
% radiusLoc    = 20*pixlespdegree;
% [xCenter, yCenter] = RectCenter(winRect);
% % X and Y coordinates of the points defining out polygon, centred on the     获取这些点的坐标（以屏幕中心为中心点）
% % centre of the screen
% yPosVectorLoc = sin(anglesRadLoc) .* radiusLoc + yCenter;
% xPosVectorLoc = cos(anglesRadLoc) .* radiusLoc + xCenter*3/2;
% locIndex      = randperm(Num,3);
% squarePos     = [xPosVectorLoc(locIndex(1)),yPosVectorLoc(locIndex(1))]';
% circlePos     = [xPosVectorLoc(locIndex(2)),yPosVectorLoc(locIndex(2))]';
% diamonPos     = [xPosVectorLoc(locIndex(3)),yPosVectorLoc(locIndex(3))]';
% 
% 	TouchQueueCreate(win, dev(1));
% 
% 
% Screen('DrawDots', win, squarePos,80,[0 255 0],[0,0],2);
% Screen('DrawDots', win, circlePos,80,[255 0 0]);
% % Screen('DrawDots', win, [xPosVectorLoc(locIndex(4)),yPosVectorLoc(locIndex(4))]',80,[0 255 0],[0,0],3);
% % Screen('DrawDots', win, [xPosVectorLoc(locIndex(5)),yPosVectorLoc(locIndex(5))]',80,[255 0 0]);
% % Screen('DrawDots', win, [xPosVectorLoc(locIndex(6)),yPosVectorLoc(locIndex(6))]',80,[0 255 0],[0,0],3);
% % Screen('DrawDots', win, [xPosVectorLoc(locIndex(7)),yPosVectorLoc(locIndex(7))]',80,[255 0 0]);
% % Screen('DrawDots', win, [xPosVectorLoc(locIndex(8)),yPosVectorLoc(locIndex(8))]',80,[0 255 0],[0,0],3);
% 
% % Screen('DrawDots', win, [target_x_right,target_y],100,[0 255 0]);
% % Number of sides for our polygon    多边形的边数
% numSides = 3;
% 
% % Angles at which our polygon vertices endpoints will be. We start at zero   多边形顶点处的角度
% % and then equally space vertex endpoints around the edge of a circle. The   从0开始，在圆的周围均匀分布顶点，然后依次连接这些点来定义多边形
% % polygon is then defined by sequentially joining these end points.
% anglesDeg = linspace(0, 360, numSides + 1);
% anglesRad = anglesDeg * (pi / 180);
% radius    = 50;
% % [xCenter, yCenter] = RectCenter(winRect);
% % X and Y coordinates of the points defining out polygon, centred on the     获取这些点的坐标（以屏幕中心为中心点）
% % centre of the screen
% yPosVector = sin(anglesRad) .* radius + diamonPos(2);
% xPosVector = cos(anglesRad) .* radius + diamonPos(1);
% 
% % Set the color of the rect to red   设置颜色
% rectColor = [0 0 255];
% 
% % Cue to tell PTB that the polygon is convex (concave polygons require much       告知PTB这个多边形是凸的
% % more processing)
% isConvex = 1;
% 
% % Draw the rect to the screen  绘制（这里对坐标数组进行转置，是由于点坐标这一参数的要求，2*n的矩阵，每行为一个点的坐标）
% Screen('FillPoly', win, rectColor, [xPosVector; yPosVector]',isConvex);
% 
% Screen('Flip', win);
% % % 
% % % % in=[deg2rad(0),10; deg2rad(45),10; deg2rad(90),10; deg2rad(135),10;...
% % % 	deg2rad(180),10; deg2rad(225),10; deg2rad(270),10];
% % % [x,y] = pol2cart(in(:,1), in(:,2));
% % 
