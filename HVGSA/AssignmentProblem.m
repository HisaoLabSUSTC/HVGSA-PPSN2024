function [Nflat, NFflat] = AssignmentProblem(x, N, r, Archive, Problem)
    %% Inputs:
    % x: N by D
    % Archive.decs: SIZE by D
    
    % Initialize Neighbor
    Nflat = zeros(r, N * Problem.D);
    NFflat = zeros(r, N * Problem.M);
    
    decs = Archive.decs; 
    
    for i = 1 : N
        row = x(i, :);
        distance = sum((decs - row).^2, 2);
        distance(distance == 0) = inf;

        [~, sortedIndices] = sort(distance, 'ascend');

        % pair = sortedIndices(1:2);
        % pointer = 3;
        % if r 
        % for j=3:r
        %     % select nearest distance
            
        cutoff = sortedIndices(1:r);

        XstartIndex = (i-1) * Problem.D + 1;
        YstartIndex = (i-1) * Problem.M + 1;
        XendIndex = i * Problem.D;
        YendIndex = i * Problem.M;
        
        for j = 1 : r
            pop = Archive(sortedIndices(j));
            decflat = reshape(pop.decs', 1, []);
            objflat = reshape(pop.objs', 1, []);
            % disp(j);
            % disp(pop);
            % disp(decflat);
            Nflat(j, XstartIndex:XendIndex) = decflat;
            NFflat(j, YstartIndex:YendIndex) = objflat;
        end
    end
end