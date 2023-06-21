function [distribution] = asymmetric_binomial(lambda)
% Compute the joint distribution of Bernoulli random variables
% N           : the number of Bernoulli random variables
% distribution: the joint distribution
N = length(lambda);
distribution = zeros(1, N+1);

parfor n = 0:N
    set_comb = nchoosek(1:N, n);
    num_comb = nchoosek(N, n);
    
    if n == 0
        distribution(n+1) = prod(1 - lambda);
    else
        for b = 1:num_comb
            p = 1 - lambda;
            p(set_comb(b, :)) = 1 - p(set_comb(b, :));
            distribution(n+1) = distribution(n+1) + prod(p);
        end
    end
    
end


