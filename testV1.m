clear;close;sca;




rMfront= arduinoManager('port','/dev/ttyACM0');rMfront.open;rMfront.shield='old'; % old or new, because the old one was sold out!
rMback = arduinoManager('port','/dev/ttyACM1');rMback.open; rMback.shield ='new';
%Audio Manager
if ~exist('aM','var') || isempty(aM) || ~isa(aM,'audioManager')
	aM=audioManager;
end
aM.silentMode = false;
if ~aM.isSetup;	aM.setup; end

sM       = screenManager('backgroundColour', [0 0 0],'blend',true);
sv       = sM.open;
choice   = 2;
tMfront  = touchManager('device', choice); % touch for front panel
tMfront.setup(sM);

ana.expType  = {'Control','Audience Effect','Altruism','Envy','Competition','Cooperation','test2touch'};%
ana.taskName = ana.expType{1}; 
try
tic
	myDisc = discStimulus('colour',[0 1 0],'size',2, 'sigma', 1);
	
	tMfront.createQueue(choice);
%   tfrontM.stop;

	ms = metaStimulus;
	ms{1} = myDisc;
	%ms{2} = fCross;
	setup(ms,sM);

	% Subject's name input
	drawTextNow(sM,'Please enter your subject name...')
	subject= input ("Enter subject name:",'s');
	nameExp=[subject,'-',date,'.mat'];

	
	KbReleaseWait;
	KbQueueRelease;
	drawTextNow(sM,'Please touch the screen to release the queue...')

	% other setup
	drawTextNow(sM,'Please press ESCAPE to start experiment...')
	RestrictKeysForKbCheck(KbName('ESCAPE'));
	KbWait;
	
	trialN			= 3;
	timeOut			= 5;
	corretTrials    = 0;
	reactiontime    = zeros(trialN,1);
	for i=1:trialN
		fprintf('\n===>>> Running Trial %i\n',i);
		reward_front  = 0;
		myDisc.xPositionOut = randi([-9 -7]);
		myDisc.yPositionOut = randi([-1 1]);
		myDisc.update;
		mybox     = myDisc.mvRect;

		fprintf('--->>> Stim Box: %i %i %i %i\n',mybox);
		front = struct('X', -inf,'Y', -inf,'Pressed', 0,'InBox', 0);
		tMfront.flush(choice);
		tMfront.start(choice);
		tStart = GetSecs;
		while GetSecs < (tStart + timeOut)
			draw(ms);
			vbl   = flip(sM);
			temp  = tMfront.eventAvail(choice);
			while temp
				evt_front			= tMfront.getEvent(choice);
				if  isempty(evt_front{1,1})
					front.X       = 0;
					front.Y       = 0;
					front.Pressed = 0;
				else
					front.X         = evt_front{1,1}.MappedX;
					front.Y         = evt_front{1,1}.MappedY;
					front.Pressed   = evt_front{1,1}.Pressed;
				end
				front.InBox = checkBox(front.X, front.Y, mybox);
				fprintf('...front x=%.2f y=%.2f\n',front.X,front.Y)
%                [result, ~, ~] = tfrontM.checkTouchWindow;

				if front.InBox&&front.Pressed
					TouchQueueStop(11);
					tMfront.close(choice);
					reward_front = 1;
					corretTrials = corretTrials+1;
					disp('good monkey front');
					sM.drawBackground;
					sM.flip
					break
				end
			end

			if reward_front
				switch  ana.taskName
					case {'Control','Audience Effect'}
						disp('good monkey front');
						aM.beep(2000,0.1,0.1);
						rMfront.stepper(46);
						
						break
					case {'Altruism'}
						disp('good monkey front');
						aM.beep(2000,0.1,0.1);
						rMback.stepper(46);
						break
					case {'Envy'}
						disp('good monkey front');
						aM.beep(2000,0.1,0.1);
						rMback.stepper(46);
						rMfront.stepper(46);
						break
				end

			end
		end

		if reward_front==0
			sM.drawBackground;
			sM.flip
			aM.beep(1000,0.1,0.1);
			WaitSecs(1);
		else
			fprintf('\n===>>> Trial %i took %.4f seconds\n',i, GetSecs-tStart);
			reactiontime(i,1) = GetSecs-tStart;
			
			if reward_front
				drawTextNow(sM,'FRONT CORRECT!')
			end
		end

		WaitSecs(4);
	end
toc
	%% Saving experiment information and results in a file called Socialtask_SubjectX.mat (X is subject number)
	results.subject = subject;
	results.trialN = trialN;
	results.corretTrials = corretTrials;
	results.reactiontime = reactiontime;
	results.TotalTime = toc/60;
	%fout=sprintf('Socialtask_Subject%d.mat', subject);
	save(nameExp, 'results');

	%%========================================
	%  rM.stop;
	TouchQueueStop(11);
	tMfront.close(choice);
	rMback.close;rMfront.close;
	sM.close;ms.reset;sca;
catch ME
	sM.close;sca;
	rethrow(ME)
end


function touched = checkBox(x, y, box)
touched = 0;
checkWin= 0;
if x>box(1)-checkWin && x<box(3)+checkWin && y>box(2)-checkWin&&y<box(4)+checkWin
	touched = 1;
end
end