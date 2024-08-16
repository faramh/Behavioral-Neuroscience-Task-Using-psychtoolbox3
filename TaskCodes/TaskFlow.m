function [TrialLevel, interTrialInterval, rewardAmt, penalty, keyPressed, KeyTime, mousePos] = TaskFlow(imageArray, fractalIndices, positions, numPositions, condition, penalty, WrongCorrection, windowPtr, dimensions)
   
    % Description: Manages the presentation of fractals on the screen, handles user interactions,
    % and determines outcomes based on the interaction.
    % Inputs:
    %   imageArray - Array of fractal images.
    %   fractalIndices - Structure with indices pointing to good and bad fractal images.
    %   positions - Matrix containing the coordinates for fractal placement on the display.
    %   numPositions - Number of possible positions for fractals.
    %   condition - Current trial condition that affects the type of feedback.
    %   penalty - Struct containing penalty values for incorrect actions.
    %   WrongCorrection - Boolean indicating if correction hints are shown.
    %   windowPtr - Pointer to the active window where graphics are displayed.
    %   dimensions - Array containing dimensions of the display window.
    % Outputs:
    %   TrialLevel - Outcome of the current trial.
    %   interTrialInterval - Duration before the next trial begins.
    %   rewardAmt - Amount of reward given based on the trial outcome.
    %   penalty - Updated penalty structure after the trial.
    %   keyPressed - Key pressed during the trial.
    %   KeyTime - Timing of the key press.
    %   mousePos - Position of the mouse at the time of interaction.

    % Initialize mouse position at the center of the screen



% Calculate the center of the screen
centerX = dimensions(3) / 2;  % X-coordinate of the screen center
centerY = dimensions(4) / 2;  % Y-coordinate of the screen center

% Set the mouse cursor to the center of the screen
SetMouse(centerX, centerY, windowPtr);

% Set the size of the fractal images
fractalWidth = 85;

% Check if the condition is "TP" (target present)
if (condition == "TP")
    % Select a random target position
    targetIndex = randi(numPositions);
    
    % Define the rectangle for the target fractal image
    fractalRect = [positions(1, targetIndex) - fractalWidth, positions(2, targetIndex) - fractalWidth, ...
                   positions(1, targetIndex) + fractalWidth, positions(2, targetIndex) + fractalWidth];
    
    % Create a texture for the target fractal image
    texture = Screen('MakeTexture', windowPtr, imageArray{fractalIndices.good});
    
    % Draw the target fractal image on the screen
    Screen('DrawTexture', windowPtr, texture, [], fractalRect);
    
    % If wrong correction is enabled, draw a green border around the target fractal
    if (WrongCorrection)
        borderRect = [positions(1, targetIndex) - fractalWidth * 2/3, positions(2, targetIndex) - fractalWidth * 2/3, ...
                      positions(1, targetIndex) + fractalWidth * 2/3, positions(2, targetIndex) + fractalWidth * 2/3];
        Screen('FrameRect', windowPtr, [0 255 0], borderRect, 4);
    end
else
    % If the condition is not "TP", set targetIndex to 0
    targetIndex = 0;
end

% Initialize counter for bad fractals
countBad = 0;

% Loop through all positions
for idx = 1:numPositions
    % Skip the target position
    if (idx ~= targetIndex)
        countBad = countBad + 1;
        
        % Define the rectangle for the bad fractal image
        fractalRect = [positions(1, idx) - fractalWidth, positions(2, idx) - fractalWidth, ...
                       positions(1, idx) + fractalWidth, positions(2, idx) + fractalWidth];
        
        % Create a texture for the bad fractal image
        texture = Screen('MakeTexture', windowPtr, imageArray{fractalIndices.bad(countBad)});
        
        % Draw the bad fractal image on the screen
        Screen('DrawTexture', windowPtr, texture, [], fractalRect);
        
        % If wrong correction is enabled, draw a red border around the bad fractal
        if (WrongCorrection)
            borderRect = [positions(1, idx) - fractalWidth * 2/3, positions(2, idx) - fractalWidth * 2/3, ...
                          positions(1, idx) + fractalWidth * 2/3, positions(2, idx) + fractalWidth * 2/3];
            Screen('FrameRect', windowPtr, [255 0 0], borderRect, 4);
        end
    end
end

% Flip the screen to display the fractals
Screen('Flip', windowPtr);

% Wait for user input (mouse click or timeout)
mouseButtonPressed = 0;
startTime = GetSecs;  % Record the start time of the response period

% Loop until a mouse button is pressed or 3 seconds have passed
while (GetSecs - startTime <= 3)
    while (~mouseButtonPressed(1)) && (GetSecs - startTime <= 3)
        % Get the current mouse position and button state
        [mouseX, mouseY, mouseButtonPressed] = GetMouse(windowPtr);
    end
end

% Record the final mouse position
mousePos = [mouseX, mouseY];

% Check for keyboard inputs
[~, KeyTime, ~, ~, ~] = KbQueueCheck(-1);

% If the space key is pressed
if (KeyTime(32) > 0)
    keyPressed = 'Space';
    handleSpaceKey;  % Call function to handle space key press
elseif (mouseButtonPressed(1))  % If a mouse click is detected
    interactionResult = SelectionCheck(positions, targetIndex, mouseX, mouseY, fractalWidth);
    handleMouseClick(interactionResult);  % Call function to handle mouse click
else
    % Default case if no input is detected
    TrialLevel = 3;
    interTrialInterval = 1.5;
    keyPressed = 'None';
    rewardAmt = 0;
end

% Function to handle space key press
function handleSpaceKey
    if (condition == "TP")
        % If condition is "TP", reset penalty and set trial level and reward
        penalty.value = 0;
        TrialLevel = 5;
        interTrialInterval = 0.2;
        rewardAmt = 0;
    else
        % If condition is not "TP", update penalty and set trial level and reward
        if (penalty.value >= penalty.threshold)
            penalty.value = 0;
            penalty.threshold = randi([2 4]);
            TrialLevel = 4;
            interTrialInterval = 1.5;
            rewardAmt = 2;
        else
            penalty.value = penalty.value + 1;
            TrialLevel = 5;
            interTrialInterval = 0.2;
            rewardAmt = 0;
        end
    end
end

% Function to handle mouse click
function handleMouseClick(result)
    interTrialInterval = 1.5;
    if (result == 1)
        % If the result is 1, set trial level and reward for correct click
        TrialLevel = 4;
        keyPressed = 'Click';
        rewardAmt = 1;
    elseif (result == 2)
        % If the result is 2, set trial level and reward for correct click with bonus
        TrialLevel = 4;
        keyPressed = 'Click';
        rewardAmt = 3;
    else
        % If the result is neither 1 nor 2, set trial level and reward for incorrect click
        TrialLevel = 3;
        keyPressed = 'None';
        rewardAmt = 0;
    end
end
end
function isOnFractal = SelectionCheck(fractal_positions, target_index, Xpos, Ypos, width)
    % Function: SelectionCheck
    % Purpose: Check if the mouse is over any fractal and identify if it's the target fractal.
    % Inputs:
    %   fractal_positions - Matrix of fractal positions on the display.
    %   target_index - Index of the 'good' fractal that needs special checking.
    %   Xpos, Ypos - Current x and y positions of the mouse.
    %   width - Half the width of the bounding box around each fractal.
    % Outputs:
    %   isOnFractal - 0 if the mouse is not on any fractal, 1 if on a non-target fractal, 2 if on the target fractal.

    numFractals = size(fractal_positions, 2);  % Get the number of fractals based on positions provided
    isOnFractal = 0;  % Initialize the output to 0 (mouse is not on any fractal)

    % Loop through each fractal position to check if the mouse is over it
    for index = 1:numFractals
        if (Xpos >= fractal_positions(1, index) - width) && (Xpos <= fractal_positions(1, index) + width) && ...
           (Ypos >= fractal_positions(2, index) - width) && (Ypos <= fractal_positions(2, index) + width)
            % Check if the current fractal is the target fractal
            if (index == target_index)
                isOnFractal = 2;  % Mouse is on the target fractal
            else
                isOnFractal = 1;  % Mouse is on a non-target fractal
            end
        end



    end
    
end
