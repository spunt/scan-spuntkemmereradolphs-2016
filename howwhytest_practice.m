function howwhytest_practice(subjectID,inputDevice,w,test_tag)

    Screen('Preference', 'SkipSyncTests', 1);
    KbName('UnifyKeyNames');
    % ====================
    % DEFAULTS
    % ====================

    %% Paths %%
    basedir = pwd;
    datadir = fullfile(basedir, 'data');
    stimdir = fullfile(basedir, 'stimuli');
    designdir = fullfile(basedir, 'design');
    utilitydir = fullfile(basedir, 'ptb-utilities');
    addpath(utilitydir)

    %% Text %%
    theFont='Arial';    % default font
    theFontSize=54;     % default font size
    fontwrap=42;        % default font wrapping (arg to DrawFormattedText)

    %% Desired Screen Resolution %%
    desired_res = [1024 768];

    %% Timing %%
    qdur = 1.5; % duration of question (s)
    adur = 2.25;   % max duration of action (s)
    betweendur = .25; % duration of blank screen between question & photo (s)

    %% Response Keys %%
    trigger = KbName('5%');
    valid_keys = {'1!' '2@' '3#' '4$'};
    start_keys = {'1!'};

    % ====================
    % END DEFAULTS
    % ====================

    %% Print Title %%
    script_name='-- How and Why Test --'; boxTop(1:length(script_name))='=';
    fprintf('%s\n%s\n%s\n',boxTop,script_name,boxTop)

    if nargin==0

        %% Get Subject ID %%
        subjectID = ptb_get_input_string('\nEnter subject ID: ');

        %% Setup Input Device(s) %%
        inputDevice = ptb_get_resp_device('Choose Participant Response Device'); % input device

        %% Initialize Screen %%
        w = ptb_setup_screen(0,250,theFont,theFontSize,desired_res); % setup screen

    end
    resp_set = ptb_response_set(valid_keys); % response set
    resp_set_start = ptb_response_set(start_keys);
    screenres = w.res(3:4); % screen resolution

    %% Font Size %%
    Screen('TextSize',w.win,theFontSize);

    %% Load Design and Setup Seeker Variable %%
    load([designdir filesep 'howwhytest_practice_design.mat'])
    ntrials = length(Seeker(:,1));
    Seeker(:,6:10) = 0;
    Seeker(:,6) = Seeker(:,5) + qdur + betweendur;
    totalTime = round(Seeker(end,6) + adur + 2);

    %% SEEKER column key %%
    % 1 - trial #
    % 2 - cond (1=1to2, 2=2to3, 3=3to4, 4=2to1, 5=3to2, 6=4to3)
    % 3 - correct (normative) response (1=Yes, 2=No)
    % 4 - stimulus # (corresponds to row in stim & data, see above)
    % 5 - scheduled question onset
    % 6 - (added above) scheduled action onset
    % 7 - (added below) actual question onset (s)
    % 8 - (added below) actual action onset (s)
    % 9 - (added below) actual response [0 if NR]
    % 10 - (added below) response time (s) [0 if NR]

    Screen('TextSize',w.win,theFontSize);

    %% Load Stimuli %%
    DrawFormattedText(w.win,'LOADING','center','center',w.white,fontwrap);
    Screen('Flip',w.win);
    instructTex = Screen('MakeTexture', w.win, imread([stimdir filesep 'howwhytest_instructions.jpg']));
    fixTex = Screen('MakeTexture', w.win, imread([stimdir filesep 'fixation.jpg']));
    scaleTex = Screen('MakeTexture', w.win, imread([stimdir filesep 'howwhytest_scale.jpg']));

    allcue = stim(Seeker(:,4),2);
    allact = stim(Seeker(:,4),3);
    allprompt = allcue;
    allprompt(Seeker(:,2)<4) = {'Why '};
    allprompt(Seeker(:,2)>3) = {'How to '};
    for s = 1:length(allcue)
        act = allact{s};
        act(end+1) = '.';
        act(1) = upper(act(1));
        allact{s} = act;
        cue = allcue{s};
        cue(end+1) = '?';
        allcue{s} = cue;
        [px(s) py(s)] = ptb_center_position(allprompt{s},w.win,-30);
        [cx(s) cy(s)] = ptb_center_position(allcue{s},w.win,30);
        [ax(s) ay(s)] = ptb_center_position(allact{s},w.win);
    end

    % ====================
    % START TASK
    % ====================

    %% Present Instructions %%
    Screen('DrawTexture',w.win, instructTex); Screen('Flip',w.win);

    %% Wait for Button Press to Start %%
    [resp rt] = ptb_get_resp(inputDevice, resp_set_start);
    anchor=GetSecs;

    %% End here if just running Test %%
    if exist('test_tag','var') && test_tag, return, end

    %% Loop Over Trials %%
    try

        for t = 1:ntrials

            %% Present Fixation %%
            Screen('DrawTexture',w.win, fixTex); Screen('Flip',w.win);

            %% Prepare Question Stimulus While Waiting %%
            Screen('DrawText',w.win,allprompt{t},px(t),py(t));
            Screen('DrawText',w.win,allcue{t},cx(t),cy(t));
            WaitSecs('UntilTime', anchor + Seeker(t,5));

            %% Present Question Stimulus and Prepare Blank Screen While Waiting %%
            Screen('Flip',w.win);
            Seeker(t,7) = GetSecs - anchor;
            Screen('FillRect', w.win, w.black);
            WaitSecs('UntilTime', anchor + Seeker(t,6) - betweendur);

            %% Present Blank and Prepare Action Stimulus While Waiting %%
            Screen('Flip',w.win);
            Screen('DrawTexture',w.win, scaleTex);
            Screen('DrawText',w.win,allact{t},ax(t),ay(t));
            WaitSecs('UntilTime', anchor + Seeker(t,6));

            %% Present Action Stimulus and Wait for Response %%
            Screen('Flip',w.win);
            onset = GetSecs;
            Seeker(t,8) = onset - anchor;
            Screen('DrawTexture',w.win, fixTex);
            resp = [];
            [resp rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, adur);
            offset = GetSecs;

            %% Present Fixation and Listen a Little Longer for a Response %%
            Screen('Flip',w.win);
            if isempty(resp)
                [resp rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, .75);
                rt = rt+adur;
            end
            if ~isempty(resp)
                Seeker(t,9) = str2num(resp(1));
                Seeker(t,10) = rt;
            end

        end

        %% Wait Until End %%
        WaitSecs('UntilTime', anchor + totalTime);

    catch

        Screen('CloseAll');
        Priority(0);
        ShowCursor;
        psychrethrow(psychlasterror);

    end

    %% Save Data to Matlab Variable %%
    d=clock;
    outfile=sprintf('howwhytest_practice_%s_%s_%02.0f-%02.0f.mat',subjectID,date,d(4),d(5));
    try
        save([datadir filesep outfile], 'subjectID', 'Seeker', 'stim');
    catch
    	fprintf('couldn''t save %s\n saving to howwhytest.mat\n',outfile);
    	save howwhytest
    end;

    if nargin==0
        %% Exit %%
        Screen('CloseAll');
        Priority(0);
        ShowCursor;
    end
