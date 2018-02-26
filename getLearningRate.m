function bestlr = getLearningRate(firstHalf, secondHalf, reversals, rangeAroundReversal)
lr = linspace(0.1,1,100);
corrs = zeros(1,length(lr));
param = KTD_defparam;
%number of reversals
reversalPoint = size(firstHalf.csLicks.before,2);
mainData = [firstHalf.csLicks.before(reversals,:) secondHalf.csLicks.after(reversals,:)];
numTrials = size(mainData,2);
n = size(mainData,1);
rewards = [firstHalf.ReinforcementOutcome.before(reversals,:) secondHalf.ReinforcementOutcome.after(reversals,:)];
valves = [firstHalf.OdorValveIndex.before(reversals,:) secondHalf.OdorValveIndex.after(reversals,:)];
dataRange = rangeAroundReversal + reversalPoint;
for lrc = 1:length(lr)
    lrc
    datas = nan(n,numTrials);
    models = nan(n,numTrials);
    zscores = zeros(n,numTrials);
    totalCorr = 0;
    for reversal = 1:n
        data = mainData(reversal,:);
        notnans = find(~isnan(data));
        numTrials = length(data); 
        rw = rewards(reversal,:);
        reward = zeros(numTrials,1);
        X = zeros(numTrials,2);
        X(valves(reversal,:) == 1,1) = 1;
        X(valves(reversal,:) == 2,2) = 1;
        emptyCells = (cellfun(@isempty,rw));
        for i = (1:numTrials)
          if(emptyCells(i))
             reward(i) = 0;
          elseif(rw(i) == "Reward")
             reward(i) = 1;
          elseif(rw(i) == "Punish")
             reward(i) = -1;
          else
             %X(i,1) = 0;
             %X(i,2) = 0;
             reward(i) = 0;
          end
        end
        param.s = lr(1,lrc);
        param.q = 0.01;
        param.std = 1;
        param.lr = lr(1,lrc);
        if(isempty(find(X(:,2))) == 0)
            plus =2;
        else
            plus = 1;
        end
        model = kalmanRW(X,reward,param);    
        rhat = zeros(n,1); % Predicted reward
        pe = zeros(2,1); % prediction error
        w = zeros(2,numTrials); % weights
        Kn = zeros(2,numTrials); % Kalman gain
        offDiag = zeros(numTrials,1); % off diagonal term in posterior weight covariance matrix
        onDiag = zeros(2,numTrials); % on diagonal terms
        output = zeros(1,numTrials);
        for counter = 1:numTrials
           rhat(counter) = model(counter).rhat;
           pe(counter) = model(counter).dt;
           w(:,counter) = model(counter).w0;
           Kn(:,counter) = model(counter).K;
           offDiag(counter) = model(counter).C(2,1); % covariance matrix is symmetric so bottom left or top right corner of 2,2 matrix are equivalent
           onDiag(:,counter) = [model(counter).C(1,1); model(counter).C(2,2)];
           output(1,counter) = w(plus,counter);
        end
        errorReversals(reversal,valves(reversal,:) == plus) = abs(output(valves(reversal,:) == plus) - mainData(reversal,valves(reversal,:) == plus));
        models(reversal,:) = output;
       
    end
    corrs(lrc) = corr(nanmean(mainData(:,dataRange))', nanmean(models(:,dataRange))');
    
end
bestlr = corrs;
figure;
plot(lr,corrs);