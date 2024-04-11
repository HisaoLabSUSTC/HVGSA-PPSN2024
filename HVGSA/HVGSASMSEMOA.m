classdef HVGSASMSEMOA < ALGORITHM
% <multi> <real/integer/label/binary/permutation>
% Hypervolume Contribution Selection with Gradient Subspace Approximation 
% r --- 50 --- number of neighbors formed
% k --- 10 --- number of unique nearest-neighbors to sample
% eta --- 50 --- learn rate
% teamCap --- 5 --- cap for local search population size
% rest --- 10 --- rest time for search team

%------------------------------- Reference --------------------------------

%------------------------------- Copyright --------------------------------
% Copyright (c) 2023 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

%% 1. Team selection
%% 2. GSA
%% 3. Environmental selection

    methods
        function main(Algorithm,Problem)
            %% Parameter setting
            [r, k, eta, teamCap, rest] = Algorithm.ParameterSet(50, 10, 50, 5, 10);

            %% Generate random population
            Population = Problem.Initialization();

            Archive = repmat(SOLUTION, 1, Problem.N * Problem.M);
            Archive(1:Problem.N) = Population; % 1 x N SOLUTION array. Add by [Archive, Individual]
            pointer = 1 + Problem.N; % pointer to first null element of array

            ref = max(Population.objs, [], 1)*1.1;
            counter = rest + 1;

            %% Optimization
            while Algorithm.NotTerminated(Population)
                drawnow('limitrate');

                %% 1 Team selection
                [FrontNo, ~] = NDSort(Population.objs, inf);
                NDFront = Population(FrontNo==1);                
                teamCandidateCount = size(NDFront, 2);
                if teamCandidateCount > teamCap
                    % CrowdDis = CrowdingDistance(NDFront.objs);
                    % [~,Rank] = sort(CrowdDis,'descend');
                    % idx = weightedRandom(size(Rank, 2), searchTeamLimit, 1);
                    % NDFront = NDFront(Rank(idx));
                    deltaS = inf(1,size(NDFront, 2));
                    PopObj = NDFront.objs;
                    [N,M]     = size(PopObj);
                    if M == 2
                        [~,rank] = sortrows(PopObj);
                        for i = 2 : N-1
                            deltaS(rank(i)) = (PopObj(rank(i+1),1)-PopObj(rank(i),1)).*(PopObj(rank(i-1),2)-PopObj(rank(i),2));
                        end
                    elseif N > 1
                        for i=1:N
                            deltaS(i) = CalHVC(PopObj, max(PopObj,[],1)*1.1, i);
                        end
                    end

                    [~, Rank] = sort(deltaS, 'descend');
                    idx = weightedRandom(size(Rank, 2), teamCap, 1);
                    NDFront = NDFront(Rank(idx));
                    % NDFront = NDFront(1:searchTeamLimit);
                end

                N = size(NDFront, 2);
                
                %% 2 GSA
                if N ~= 0 && counter > rest
                    [x0, y0, x0flat, y0flat] = QuickAssign(NDFront);
                    [KNNflat, KNNFflat] = AssignmentProblem(x0, N, k, Archive, Problem);
                    [Nflat, NFflat] = generateUniquePopulations(KNNflat, KNNFflat, r, k, Problem, N);
    
                    HVC = Hypervolume(y0flat, ref);
                    NHVC = Hypervolume(NFflat, ref);
    
                    [v, V, l] = GSA(x0flat, HVC, Nflat, NHVC);
    
                    gsd = v';
    
                    x0flat = x0flat + gsd * eta;      
    
                    x0 = reshape(x0flat, [], N)';
                    y0 = reshape(y0flat, [], N)';
    
                    NDFront = Problem.Evaluation(reshape(x0flat, [], N)');
                    [pointer, Archive] = Store(Archive, NDFront, pointer);
                    counter = 0;
                end
                %% End of GSA
                counter = counter + 1;

                %% 3. Environmental selection
                for i=1:N
                    [Population,FrontNo] = Reduce([Population,NDFront(i)],FrontNo);
                end

                for i=1:Problem.N-N
                    Offspring = OperatorGAhalf(Problem,Population(randperm(end,2)));
                    [pointer, Archive] = Store(Archive, Offspring, pointer);
                    [Population,FrontNo] = Reduce([Population,Offspring],FrontNo);
                end

                ref = max(Population.objs, [], 1)*1.1;
                % Visualize(Population);
            end
        end
    end
end

function [Res, ResF] = generateUniquePopulations(Neighbor, NeighborF, r, k, Problem, N)
    % matrix is the k x DN matrix.
    % D is the decision space dimensionality.
    % k is the number of nearest neighbors in the original matrix
    % r is the number of unique new populations to generate.

    %% This method permutes neighbor individuals to create unique population
    %% for the GSA step.
    
    D = Problem.D;
    M = Problem.M;

    % Initialize the cell array to store unique rows as strings for comparison.
    uniqueRows = {};
    
    Res = zeros(r, D*N);
    ResF = zeros(r, M*N);
    
    % Counter for how many unique populations have been generated.
    generated = 0;
    counter = 0;
    while generated < r
        % Generate a new population row.
        newRow = zeros(1, D*N);
        newRowF = zeros(1, M*N);
        for i = 1:N
            % Randomly select one population for the i-th individual.
            chosenPop = randi(k);
            
            % Indexing for the individuals.
            idxStart = (i-1)*D + 1;
            idxEnd = i*D;
            idxStartF = (i-1)*M + 1;
            idxEndF = i*M;
            
            % Fill the new row with the selected individual.
            newRow(idxStart:idxEnd) = Neighbor(chosenPop, idxStart:idxEnd);
            newRowF(idxStartF:idxEndF) = NeighborF(chosenPop, idxStartF:idxEndF);
        end
        
        % Convert the row to a string for easy comparison.
        rowStr = mat2str(newRow);
        
        % Check if this row is unique.
        if ~ismember(rowStr, uniqueRows)
            % If unique, add it to the list and to the output matrix.
            generated = generated + 1;
            uniqueRows{end+1} = rowStr;
            Res(generated, :) = newRow;
            ResF(generated, :) = newRowF;
        end
        % If not unique, the loop repeats without incrementing 'generated'.
        counter = counter + 1;
        if counter >= generated * 2
            assert(false, "k is set too low/r is set to high")
        end
    end
end



function HVC = CalHVC(PopObj, RefPoint, i)
    data = PopObj;
    s = data(i, :);
    data(i, :) = [];
    data = max(s, data);
    HVC = prod(RefPoint-s)-stk_dominatedhv(data, RefPoint);
end

function Visualize(Population)
    result = Population.objs';
    hold on;
    scatter(result(1,:),result(2,:),'.');
    pause(0.5);
end

function VisualizeE(y0)
    hold off;
    scatter(y0(:,1),y0(:,2),'.');
    % xlim([0 1]);
    % ylim([0 10]);
    pause(0.01);
    
end

function VisualizeR(y1)
    hold on;
    scatter(y1(:,1),y1(:,2),'o');
    % xlim([0 1]);
    % ylim([0 10]);    
    pause(0.1);
end

function [pointer, Archive] = Store(Archive, Population, pointer)
    N = size(Population, 2);
    odecs = Archive.decs;
    ndecs = Population.decs;

    leftover = [];
    flag = 0;

    for i=1:N
        if ~ismember(ndecs(i, :), odecs)
            if pointer == size(Archive, 2) + 1
                % find dominated solution, if can't, find most dense (flag)
                DI = find(stk_isdominated(Archive.objs, Population(i).objs), 1);
                if size(DI, 1) ~= 0
                    Archive(DI) = Population(i);
                else
                    leftover = [leftover, Population(i)];
                    flag = 1;
                end
            else
                Archive(pointer) = Population(i);
                pointer = pointer + 1;
            end
        end
    end

    if flag % find most dense
        All = [Archive, leftover];
        Distance = pdist2(All.objs,All.objs);
        Distance(logical(eye(length(Distance)))) = inf;
        Del = false(1,size(All.objs,1));
        while sum(Del) > pointer
            Remain   = find(~Del);
            Temp     = sort(Distance(Remain,Remain),2);
            [~,Rank] = sortrows(Temp);
            Del(Remain(Rank(1))) = true;
        end

        % CrowdDis = CrowdingDistance(All.objs, );
        % [~,Rank] = sort(CrowdDis,'descend');
        % Archive = All(Rank(1:pointer));    
    end
end


function [x, y, xf, yf] = QuickAssign(Population)
    % nonflat -> flat: reshape(nonflat', 1, [])
    % flat -> nonflat: reshape(flat, [], N)'
    x = Population.decs;
    y = Population.objs;
    xf = reshape(x', 1, []);
    yf = reshape(y', 1, []);
end

function sampledNumbers = weightedRandom(rangeEnd, numSamples, lambda)
    % rangeEnd: The end of the range (N)
    % numSamples: The number of unique numbers to generate
    % lambda: Decay rate for the exponential probability distribution

    %% This method makes it so team selection doesn't always favor the top
    %% members, adds randomness to the selection.

    assert(numSamples <= rangeEnd, 'numSamples must be less or equal to rangeEnd.');

    % Initial probabilities based on exponential decay
    p = exp(-lambda * (1:rangeEnd));
    p = p / sum(p); % Normalize

    values = 1:rangeEnd; % Possible values to sample
    sampledNumbers = zeros(1, numSamples);

    for i = 1:numSamples
        % Sample a number according to the modified probabilities
        idx = randsample(values, 1, true, p);
        sampledNumbers(i) = idx;

        % Remove the selected number from the pool
        calibrated_id = find(values==idx);
        values(calibrated_id) = [];
        p(calibrated_id) = [];

        % Re-normalize the probabilities
        p = p / sum(p);
    end
end
