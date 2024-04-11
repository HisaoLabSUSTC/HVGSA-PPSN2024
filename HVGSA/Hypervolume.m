function HV = Hypervolume(y,ref)
    [r,~] = size(y);
    M = size(ref, 2);
    HV = zeros(r,1);
    % flat -> nonflat: reshape(flat, [], N)'
    for i=1:r
       objflat = y(i,:);
       obj = reshape(objflat, M, [])';
       HV(i) = stk_dominatedhv(obj,ref);  
    end
end

% function IGD = IGDp(PopObj, optimum)
%     if size(PopObj, 2) ~= size(optimim, 2)
%         IGD = nan;
%     else
%         [Nr, M] = size(optimum);
%         [N, ~] = size(PopObj);
%         delta = zeros(Nr, 1);
%         for i=1:Nr
%             delta(i) = min(sqrt(sum(max(PopObj-repmat(optimum(i,:),N,1),zeros(N,M)).^2,2)));
%         end
%         IGD = sum(delta);
%     end
% end
