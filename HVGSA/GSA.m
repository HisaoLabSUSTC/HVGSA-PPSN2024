function [v, V, lambda] = GSA(x,x_objVal,Neighbor,N_objVals)
% x=1*d vector
% x_objVal=1*1 scalar
% Neighbor=r*d matrix
% N_objVals=r*1 vector

    % eps = 1e-4;
    d=(N_objVals-x_objVal)./(vecnorm(Neighbor-x,2,2)); %r*1
    V=((Neighbor-x)./(vecnorm(Neighbor-x,2,2)))'; %d*r

    
    % Proof of V^TV is positive definite can be found in 
    % Schutze et al., Gradient subspace approximation: a direct search method for memetic computing
    try
        % Attempt Cholesky decomposition
        R = chol(V' * V + eye(size(V, 2)), 'upper');
        lambda = R \ (R' \ (d));
    catch ME
        % If an error occurs, check if it's due to Cholesky decomposition failure
        if strcmp(ME.identifier, 'MATLAB:posdef')
            % Fallback to the backslash operator as a more general solution
            % disp('Cholesky decomposition failed, falling back to backslash operator.');
            lambda = (V' * V + eye(size(V, 2))) \ (d);
        else
            % If the error is not related to positive definiteness, rethrow it
            rethrow(ME);
        end
    end
    
    v=1/(norm(V*lambda))*(V*lambda); %d*1
end