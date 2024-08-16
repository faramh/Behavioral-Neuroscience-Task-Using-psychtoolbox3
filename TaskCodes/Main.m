% HW 2 neuroscience lab - Mohamad Hosein Faramarzi - 99104095
%Note! 
% In this implementation we have used some ready functions of previous
% implemented projects in internet and Github but definitely none this project are
% Blind copy. Also we have explained all parts using complete comments to
% ensure explaining the code in a complete way
clc; clear; close all; sca;
% This code is the main run code of Task of visual search

% Prompt user for subject ID and session number
ID = input('Please Enter the Subject ID: ');
s = input('Please Enter the session number: ');


% Constants
num_session = 4;  % Number of sessions
num_trial = 144;  % Number of trials per session
Good_fracs = 24;  % Number of good fractals
Bad_fracs = 24;  % Number of bad fractals
DS = [3 5 7 9];  % Possible display sizes
task_time = 3;  % Duration of the task
reward_time = 2;  % Duration of the reward display
total_reward = 0;  % Initialize total reward\\

% Load dataset of fractal images into a cell array
frac_im = cell(1, 48);
for i = 1:48
    % Construct file name for each fractal image
    string = sprintf('./Assignment2_fractals/%02d.jpeg', i);
    % Read and store the image
    frac_im{i} = imread(string);
end
clear string;

% Set up Psychtoolbox screen
Screen('Preference', 'SkipSyncTests', 1);
[wPtr, rect] = Screen('OpenWindow', 0);
Screen('FillRect', wPtr, [0 0 0], rect);  % Fill screen with black color
Screen('Flip', wPtr);  % Display the black screen

% Define parameters
debug_mode = 1;



% Subject and session information
subject_ID = '99104095';
session = struct('subject_ID', subject_ID, 'session_number', s, 'fractal_size', 3.81, 'peripheral_circle', 13.77, 'screen_size', [rect(3) rect(4)]);

% Initialize trial data structure
trial = struct('button_pressed', cell(1, num_trial), 'fractal_name', cell(1, num_trial), 'fractal_pos', cell(1, num_trial), 'display_size', cell(1, num_trial), 'trial_cond', cell(1, num_trial), 'mouse_pos', cell(1, num_trial));

% Generate random fractal conditions
fractals = zeros(1, Good_fracs + Bad_fracs);
fractals(1:Good_fracs) = 1;
fractals = fractals(randperm(Good_fracs + Bad_fracs));
selected_fractals = zeros(4, Good_fracs + Bad_fracs);

% Initialize keyboard queue for capturing responses
KbQueueCreate(-1);
KbQueueStart();

% Session loop (commented out for single session run)
% for s=1:num_session
Trial_level = 0;
key_pressed = 'None';



last_reward = 0;
reject_reward.value = 0;
reject_reward.threshold = randi([2 4]);  % Random threshold for reward rejection

% Generate random trial conditions and display sizes
[display_size, trial_condition] = TrialShuffles(DS, num_trial);

for tr = 1:num_trial
    % Trial_level machine controlling experiment flow
    if Trial_level == 0  % Begin Trial_level
        displayText(cat(2, 'Ready to start?'), 80, wPtr, rect);
        [~, ~, ~] = KbWait();  % Wait for key press to start
        Trial_level = 1;
    end



%This level is about the fixation of begining
    if Trial_level == 1  % Fixation Trial_level
        fixation_time = randi([300 500]) / 1000;  % Random fixation time between 300 and 500 ms
        fixation(fixation_time, wPtr, rect);
        Trial_level = 2;
    end



%In this level all main parts of trial including Displaying stimuli and
%choice happens
    if Trial_level == 2  % TaskFlow Trial_level
        % Select fractal stimuli for the trial
        [selected_fractals, fractal_num, fractal_pos] = StimuliSelection(fractals, selected_fractals, display_size(tr), trial_condition(tr));
        InfoBox(s, tr, key_pressed, total_reward, wPtr, rect);  % Display trial info
        % Run the task flow and get updated Trial_level and response details
        [Trial_level, ITI_time, last_reward, reject_reward, key_pressed, onsetPress, mouse_pos] = TaskFlow(frac_im, fractal_num, fractal_pos, display_size(tr), trial_condition(tr), reject_reward, debug_mode, wPtr, rect);
    end

%In the case on no response we have to display an alert voice so:
    if Trial_level == 3  % Error Trial_level
        Beeper(1e3, 1, 0.5);  % Play error beep sound
        Trial_level = 5;
    end



% Compute total reward in every trials based on the performance and reward
% codnditions
    if Trial_level == 4  % Reward Trial_level
        total_reward = total_reward + last_reward;  % Update total reward
        RewardTransfer(reward_time, wPtr);  % Display reward screen
        Trial_level = 5;
    end


% This is the level of ITI. Which based on the explained task design we
% have to calculate different times and show a blanck page between each
% trials
    if Trial_level == 5  % ITI (Inter-Trial Interval) Trial_level
        ITIshow(ITI_time, wPtr, rect);  % Display ITI screen
    end


%all the conditions set to begining
    Trial_level = 1;  % Reset Trial_level for next trial

    % Check for keyboard press to exit
    [~, firstPress, ~, ~, ~] = KbQueueCheck(-1);
    if (firstPress(27) + onsetPress(27) > 0)  % Check if 'Esc' key is pressed
        sca;  % Close all screens
        return;
    end
    KbQueueFlush();  % Clear keyboard queue

    % Save trial data
    trial(tr).display_size = display_size(tr);
    trial(tr).trial_cond = trial_condition(tr);
    trial(tr).fractal_name = fractal_num;
    trial(tr).fractal_pos = fractal_pos;
    trial(tr).mouse_pos = mouse_pos;
    trial(tr).button_pressed = key_pressed;
end
% end

sca;  % Close all screens at the end of the session


%% save variables
save('saved.mat', 'session', 'trial');


%functions 
function ITIshow(ITI_time, wPtr, ~)
    Screen('Flip', wPtr);
    WaitSecs(ITI_time);
end

function fixation(fixation_time, wPtr, rect)
    myColor = [255 0 0];
    x_center = rect(3)/2;
    y_center = rect(4)/2;
    
    Screen('FillOval', wPtr, myColor, [x_center-15, y_center-15, x_center+15, y_center+15]);
    Screen('Flip', wPtr);
    WaitSecs(fixation_time);
end

function RewardTransfer(reward_time, wPtr)
    Screen('Flip', wPtr);
    WaitSecs(reward_time);
end

%This function selects enough fractals based on the trial condition (either "TA" or not) and returns the selected fractals, their indices, and their positions.
function [chosen_fractals, fractal_info, position_info] = StimuliSelection(fractals_input, initial_selection, screen_dim, condition_check)
    % This function decides on the fractals to be selected based on input conditions and modifies an initial selection matrix.
    % Inputs:
    %   fractals_input - A matrix representing available fractals.
    %   initial_selection - A matrix indicating already selected fractals.
    %   screen_dim - The dimension of the display (number of possible fractal positions).
    %   condition_check - A string that determines which selection mode to use.
    % Outputs:
    %   chosen_fractals - Updated matrix of selected fractals after applying selection criteria.
    %   fractal_info - Struct containing indices of good or bad fractals depending on conditions.
    %   position_info - Array containing the positions of fractals on the display.

    % Calculate the half-dimension of the screen size, used to adjust selection matrix dimensions.
    half_dim = (screen_dim-1)/2;
    
    % Check the selection condition; if 'TA' then select based on one criterion, otherwise use another.
    if (condition_check == "TA")
        % Handle 'TA' condition: utilize another function to determine 'bad' fractals and adjust the selection matrix.
        [chosen_fractals, fractal_info.bad] = WithoutrewardSelection(fractals_input, initial_selection, screen_dim, half_dim);
    else
        % Find indices of fractals that are available (value of 1) and not yet selected (value of 0 in the corresponding position).
        valid_indices = find(fractals_input == 1 & initial_selection(half_dim, :) == 0);
        % Count the number of available indices.
        count_indices = length(valid_indices);
        
        % Check if there are any valid indices to select from.
        if (count_indices >= 1)
            % Randomly select one good fractal from the available indices.
            fractal_info.good = valid_indices(randperm(count_indices, 1));
            % Mark the selected fractal as chosen in the initial selection matrix.
            initial_selection(half_dim, fractal_info.good) = 1;
        else
            % If no valid indices are initially found, reset and re-find valid indices.
            initial_selection(half_dim, fractals_input == 1) = 0;
            valid_indices = find(fractals_input == 1 & initial_selection(half_dim, :) == 0);
            count_indices = length(valid_indices);
            fractal_info.good = valid_indices(randperm(count_indices, 1));
            initial_selection(half_dim, fractal_info.good) = 1;
        end
        % Regardless of the above conditions, process and update 'bad' fractals using the WithoutrewardSelection function.
        [chosen_fractals, fractal_info.bad] = WithoutrewardSelection(fractals_input, initial_selection, screen_dim-1, half_dim);
    end
    
    % Retrieve the position information for each fractal based on the screen dimension.
    position_info = getPosition(screen_dim);
end


function [chosen_fractals, fractal_indices] = WithoutrewardSelection(fractals, chosen_fractals, Bad_fracs, DS)
    % Find indices where fractals are not present (value == 0) and not yet selected
    zero_indices = find(fractals == 0 & chosen_fractals(DS, :) == 0);
    zero_count = length(zero_indices);  % Count these indices

    % Check if there are enough indices to fulfill the requirement
    if zero_count >= Bad_fracs
        % If enough, randomly select the required number of fractals
        fractal_indices = zero_indices(randperm(zero_count, Bad_fracs));
        chosen_fractals(DS, fractal_indices) = 1;  % Mark them as selected
    else
        % If not enough, reset chosen_fractals to unselect any selected at the current indices
        chosen_fractals(DS, fractals == 0) = 0;
        chosen_fractals(DS, zero_indices) = 1;  % Force select the available ones

        % Recheck for zero indices as previous selections may change the conditions
        additional_indices = find(fractals == 0 & chosen_fractals(DS, :) == 0);
        additional_count = length(additional_indices);

        % Select additional fractals to meet the required number
        fractal_indices = [zero_indices additional_indices(randperm(additional_count, Bad_fracs-zero_count))];
        chosen_fractals(DS, fractal_indices) = 1;  % Mark additional selections as well
    end
end


function PositionArray = getPosition(Size)
    % Get the size of the display screen
    [screen_width, screen_height] = Screen('WindowSize', 0);
    
    % Calculate the radius for fractal positioning
    radius = 0.375*screen_height;
    
    % Determine the angle increment based on the number of display positions
    angle_step = 360 / Size;
    
    % Generate angles for fractal positioning
    angles = (0:angle_step:360-angle_step) + randi(360);
    
    % Calculate the X and Y positions for fractals
    PositionArray(1, :) = screen_width/2 + (radius * cosd(angles));
    PositionArray(2, :) = screen_height/2 - (radius * sind(angles));
end





function displayText(myText, fontsize, wPtr, ~)  
    myColor = [255 255 255];
    Screen('TextSize', wPtr, fontsize);
    DrawFormattedText(wPtr, myText, 'center', 'center', myColor);
    Screen('Flip', wPtr);
end

function [display_sizes, condition_types] = TrialShuffles(screen_sizes, total_trials)
    % Purpose: This function generates randomized display sizes and corresponding trial conditions
    % for a given number of trials using predefined screen sizes.
    % Inputs:
    %   screen_sizes - An array containing different screen sizes to be assigned to trials.
    %   total_trials - Total number of trials for which to generate screen sizes and conditions.
    % Outputs:
    %   display_sizes - An array with randomized screen sizes for each trial.
    %   condition_types - An array containing trial conditions corresponding to the screen sizes.

    % Initialize the output arrays for display sizes and condition types.
    display_sizes = zeros(1, total_trials);
    condition_types = strings(1, total_trials);
    
    % Distribute screen sizes across quarters of the total number of trials.
    % The first quarter of the trials receives the first screen size, the second quarter the second,
    % the third quarter the third, and the last quarter receives the fourth screen size.
    display_sizes(1:total_trials/4) = screen_sizes(1);
    %Second quarter
    display_sizes(total_trials/4+1:total_trials/2) = screen_sizes(2);
    %third quarter
    display_sizes(total_trials/2+1:3*total_trials/4) = screen_sizes(3);
    %fourth quarter
    display_sizes(3*total_trials/4+1:total_trials) = screen_sizes(4);
    
    % Randomize the order of display sizes to ensure trials are not predictable.
    display_sizes = display_sizes(randperm(total_trials));
    
    % Prepare a temporary array to assign trial conditions 'TP' and 'TA'.
    % 'TP' is assigned to the first eighth of trials and 'TA' to the second eighth.
    trial_conditions_temp = strings(1, total_trials);
    trial_conditions_temp(1:total_trials/8) = "TP";
    trial_conditions_temp(total_trials/8+1:total_trials/4) = "TA";
    
    % Assign trial conditions based on the randomized display sizes.
    % Trials corresponding to each screen size get a shuffled subset of 'TP' and 'TA' conditions
    % such that each condition is equally likely across different display sizes.
    %first
    condition_types(display_sizes == screen_sizes(1)) = trial_conditions_temp(randperm(total_trials/4));
    %second
    condition_types(display_sizes == screen_sizes(2)) = trial_conditions_temp(randperm(total_trials/4));
    %third
    condition_types(display_sizes == screen_sizes(3)) = trial_conditions_temp(randperm(total_trials/4));
    %fourth
    condition_types(display_sizes == screen_sizes(4)) = trial_conditions_temp(randperm(total_trials/4));
end

%Here is the function to implement informationbox
function InfoBox(session_num, trial_num, key_pressed, total_reward, wPtr, rect)
    % Define the coordinates for the information display box on the screen
    Box_Pos = [rect(3)-1300, 50, rect(3)-1000, 260];
    
    % Set the text size for display
    Screen('TextSize', wPtr, 25);
    
    % Prepare the text to be displayed, concatenating various pieces of trial information
    display_text = cat(2, '\n', 'Trial Num: ', num2str(session_num), '-', num2str(trial_num), '\n', 'You pressed: ', key_pressed, '\n', 'value/perceptual', num2str(randi([1, 2])), '\n', 'Total Reward: ', num2str(total_reward));
    
    % Fill the specified rectangle with green color to create a background for the text
    Screen('FillRect', wPtr, [0 255 0], [Box_Pos(1), Box_Pos(2), Box_Pos(3), Box_Pos(2)+50]);
    
    % Set text style for the title inside the box
    Screen('TextStyle', wPtr, 1);
    DrawFormattedText(wPtr, 'Box of infos', Box_Pos(1)+20, Box_Pos(2)+35, [0 0 0]);
    
    % Reset text style to default and draw the prepared text within the box
    Screen('TextStyle', wPtr, 0);
    DrawFormattedText(wPtr, display_text, Box_Pos(1)+20, Box_Pos(2)+90, [255 255 255]);
  
end






