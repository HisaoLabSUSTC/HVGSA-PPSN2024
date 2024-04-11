%% IMPORTANT: SET THESE
path = 'PATH\TO\PlatEMO\DataWFG';
% Problems = {ZDT1(), ZDT2(), ZDT3(), ZDT4(), ZDT4C(), ZDT6()};
% Problems = {DTLZ1(), DTLZ2(), DTLZ4(), DTLZ5(), DTLZ6(), DTLZ7()};
Problems = {DTLZ4()};
% Problems = {IDTLZ1(), IDTLZ2()};
% Problems = {WFG1(), WFG2(), WFG3(), WFG4(), WFG5(), WFG6(), WFG7(), WFG8(), WFG9()};
%% SET END


n_problems = numel(Problems);
n_runs = 50;

algorithm_dirs = dir(fullfile(path, '*'));
algorithm_dirs = algorithm_dirs([algorithm_dirs.isdir]);
n_algorithms = numel(algorithm_dirs) - 2;

best_HV_index = zeros(n_algorithms, n_problems);

counter = 1;

figure;
set(gcf, 'Position', [100, 100, 1200, 800]);

for i = 1:n_algorithms
    algorithm_name = algorithm_dirs(i+2).name; % Adjust index to skip '.' and '..' entries
    
    for j = 1:n_problems
        problem_name = class(Problems{j});
        M = Problems{j}.M;
        D = Problems{j}.D;
        HV_data = zeros(1, n_runs);
        
        for k = 1:n_runs
            filename = fullfile(path, algorithm_name, sprintf('%s_%s_M%d_D%d_%d.mat', algorithm_name, problem_name, M, D, k));
            if isfile(filename)
                datum = load(filename);
                HV_data(k) = datum.metric.HV(end);
            else
                warning('File does not exist: %s', filename);
                HV_data(k) = NaN;
            end
        end
        
        % [~, bestRunIndex] = max(HV_data);
        medianHV = mean(HV_data);
        [~, bestRunIndex] = min(abs(HV_data - medianHV));
        % if algorithm_name == "HVGSASMSEMOA" && problem_name == "DTLZ1"
        %     bestRunIndex = 38;
        % end
        best_HV_index(i, j) = bestRunIndex;
        counter = (i-1)*n_problems + j;
        ax = subplot(2, n_algorithms, counter);
        
        best_data_filename = fullfile(path, algorithm_name, sprintf('%s_%s_M%d_D%d_%d.mat', algorithm_name, problem_name, M, D, best_HV_index(i,j)));
        best_datum = load(best_data_filename);
        
        % draw the objective space for the best run
        DrawObj(ax, best_datum.result{end, 2}, Problems{j});

        xlabel('');
        ylabel('');
        zlabel('');
        
        % if first row, set the title to the problem's name
        if i == 1
            title(ax, problem_name);
        end
        
        % if first column, set the ylabel to the algorithm's name
        if j == 1
            ylabel(ax, algorithm_name);
        end
    end
end



function DrawObj(ax, Population, Problem)
    axes(ax);

    % ax = Draw(Population.objs,{'\it f\rm_1','\it f\rm_2','\it f\rm_3'});
    Draw(ax, Population.objs, {'\it f\rm_1', '\it f\rm_2', '\it f\rm_3'});

    if ~isempty(Problem.PF)
        hold(ax, 'on');
        if ~iscell(Problem.PF)
            if Problem.M == 2
                plot(ax,Problem.PF(:,1),Problem.PF(:,2),'-k','LineWidth',1);
            elseif Problem.M == 3
                plot3(ax,Problem.PF(:,1),Problem.PF(:,2),Problem.PF(:,3),'-k','LineWidth',1);
            end
        else
            if Problem.M == 2
                surf(ax,Problem.PF{1},Problem.PF{2},Problem.PF{3},'EdgeColor','none','FaceColor',[.85 .85 .85]);
            elseif Problem.M == 3
                surf(ax,Problem.PF{1},Problem.PF{2},Problem.PF{3},'EdgeColor',[.8 .8 .8],'FaceColor','none');
            end
            set(ax,'Children',ax.Children(flip(1:end)));
        end
        hold(ax, 'off');
    elseif size(Problem.optimum,1) > 1 && Problem.M < 4
        hold(ax, 'on');
        if Problem.M == 2
            plot(ax,Problem.optimum(:,1),Problem.optimum(:,2),'.k');
        elseif Problem.M == 3
            plot3(ax,Problem.optimum(:,1),Problem.optimum(:,2),Problem.optimum(:,3),'.k');
        end
        hold(ax, 'off');
    end
end


function currentAxes = Draw(ax, Data,varargin)
    if size(Data,2) == 1
        Data = [(1:size(Data,1))',Data];
    end
    set(ax,'FontName','Times New Roman','FontSize',13,'NextPlot','add','Box','on','View',[0 90],'GridLineStyle','none');
    if islogical(Data)
        [ax.XLabel.String,ax.YLabel.String,ax.ZLabel.String] = deal('Solution No.','Dimension No.',[]);
    elseif size(Data,2) > 3
        [ax.XLabel.String,ax.YLabel.String,ax.ZLabel.String] = deal('Dimension No.','Value',[]);
    elseif ~isempty(varargin) && iscell(varargin{end})
        [ax.XLabel.String,ax.YLabel.String,ax.ZLabel.String] = deal(varargin{end}{:});
    end
    if ~isempty(varargin) && iscell(varargin{end})
        varargin = varargin(1:end-1);
    end
    if isempty(varargin)
        if islogical(Data)
            varargin = {'EdgeColor','none'};
        elseif size(Data,2) == 2
            varargin = {'o','MarkerSize',6,'Marker','o','Markerfacecolor',[.7 .7 .7],'Markeredgecolor',[.4 .4 .4]};
        elseif size(Data,2) == 3
            varargin = {'o','MarkerSize',8,'Marker','o','Markerfacecolor',[.7 .7 .7],'Markeredgecolor',[.4 .4 .4]};
        elseif size(Data,2) > 3
            varargin = {'-','Color',[.5 .5 .5],'LineWidth',2};
        end
    end
    if islogical(Data)
        C = zeros(size(Data)) + 0.6;
        C(~Data) = 1;
        surf(ax,zeros(size(Data')),repmat(C',1,1,3),varargin{:});
    elseif size(Data,2) == 2
        plot(ax,Data(:,1),Data(:,2),varargin{:});
    elseif size(Data,2) == 3
        plot3(ax,Data(:,1),Data(:,2),Data(:,3),varargin{:});
        view(ax,[135 30]);
    elseif size(Data,2) > 3
        Label = repmat([0.99,2:size(Data,2)-1,size(Data,2)+0.01],size(Data,1),1);
        Data(2:2:end,:)  = fliplr(Data(2:2:end,:));
        Label(2:2:end,:) = fliplr(Label(2:2:end,:));
        plot(ax,reshape(Label',[],1),reshape(Data',[],1),varargin{:});
    end
    axis(ax,'tight');
    set(ax.Toolbar,'Visible','off');
    set(ax.Toolbar,'Visible','on');

    currentAxes = ax;
end