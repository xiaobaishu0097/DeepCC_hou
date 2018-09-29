clear
clc

opts = get_opts();
data = readtable('src/visualization/file_list.csv', 'Delimiter',','); % gt@1fps
% data = readtable('src/triplet-reid/data/duke_test.csv', 'Delimiter',','); % reid

opts.net.experiment_root = 'experiments/fc256_1fps';
labels = data.Var1;
paths  = data.Var2;
%% Compute features
features = h5read(fullfile(opts.net.experiment_root, 'features.h5'),'/emb');
features = features';
% pooling
pooling = 4;
labels = labels(pooling:pooling:length(labels),:);
features = features(pooling:pooling:length(features),:);
dist = pdist2(features,features);
%% Visualize distance distribution
    same_label = triu(pdist2(labels,labels) == 0,1);
    different_label = triu(pdist2(labels,labels) ~= 0);
    pos_dists = dist(same_label);
    neg_dists = dist(different_label);
    %%
    neg_dists = randsample(neg_dists,length(pos_dists));
    %%
    neg_5th = prctile(neg_dists,5);
    m = [mean(pos_dists),mean(neg_dists)];
    s = [std(pos_dists),std(neg_dists)];
%     pos_halves = pos_dists-m(1);
%     neg_halves = neg_dists-m(2);
    mid = mean(m);
    diff = mean(neg_dists)-mean(pos_dists);
    %%
    fig = figure;
    % Enlarge figure to full screen.
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.1, 0.1, 0.7, 0.7]);
%     fig.PaperPositionMode = 'auto';
    subplot(1,2,1)
    hold on;
    histogram(pos_dists,100,'Normalization','probability', 'FaceColor', 'b');
    histogram(neg_dists,100,'Normalization','probability','FaceColor','r');
    title('Normalized distribution of pair-distances');
    errorbar(m(1),0.07,s(1),'horizontal','b-o')
    errorbar(m(2),0.07,s(2),'horizontal','r-o')
    legend('Positive','Negative','stats_P','stats_N','Location','southeast');
    stat_str_P = "mean_P:"+num2str(m(1),'%.2f')+newline+"std_P:"+num2str(s(1),'%.2f');
    stat_str_N = "mean_N:"+num2str(m(2),'%.2f')+newline+"std_N:"+num2str(s(2),'%.2f');
    neg_str = "\downarrow dist_P less than the 5% dist_N: "+num2str(sum(pos_dists<neg_5th)/length(pos_dists)*100)+"%";
    mid_str = "\downarrow dist_P less than mid: "+num2str(sum(pos_dists<mid)/length(pos_dists)*100)+"%";
    info_str = "5% dist_N: "+num2str(neg_5th,'%.2f')+newline+"mid: "+num2str(mid,'%.2f');
    dist_str = "E[d_N-d_P]: "+num2str(diff,'%.2f')+newline+"0.5dist: "+num2str(diff/2,'%.2f');
    text(mid,0.025,neg_str)
    text(mid,0.02,mid_str)
    text(mid,0.05,info_str)
    text(0,0.05,dist_str)
    text(m(1),0.065,stat_str_P)
    text(m(2),0.065,stat_str_N)
    
    % get the best partition pt
%     min_neg = prctile(neg_dists,0.1);
%     max_pos = prctile(pos_dists,99.9);
%     if min_neg>=max_pos
%         best_pt = mean([min_neg,max_pos]);
%         FP = 0;
%         FN = 0;
%     else
%         pts = 99:0.05:100;
%         pts = prctile(pos_dists,pts);
%         FPs = sum(neg_dists<pts)/numel(neg_dists);
%         FNs = sum(pos_dists>pts)/numel(pos_dists);
%         [min_total_miss,id] = min(FPs+50*FNs);
%         best_pt = pts(id);
%         FP = FPs(id);
%         FN = FNs(id);
%     end
%     best_pt_str = "\downarrow best_pt:"+num2str(best_pt)+newline+"FP: "+num2str(FP)+newline+"50x FN: "+num2str(FN);
%     text(best_pt,0.04,best_pt_str)

    hold off
    
    %%
    subplot(1,2,2)
    thres = mid;
    pos_dists = (thres-pos_dists)/diff*2;
    neg_dists = (thres-neg_dists)/diff*2;
    o5pos = sum(pos_dists>0.5)/length(pos_dists)*100;
    o5neg = sum(neg_dists<-0.5)/length(neg_dists)*100;
    
    m = [mean(pos_dists),mean(neg_dists)];
    s = [std(pos_dists),std(neg_dists)];
    
    hold on;
    histogram(pos_dists,100,'Normalization','probability', 'FaceColor', 'b');
    histogram(neg_dists,100,'Normalization','probability','FaceColor','r');
    title('Apparance score');
    errorbar(m(1),0.07,s(1),'horizontal','b-o')
    errorbar(m(2),0.07,s(2),'horizontal','r-o')
    legend('Positive','Negative','stats_P','stats_N','Location','southeast');
    
    
    stat_str_P = "mean_P:"+num2str(m(1),'%.2f')+newline+"std_P:"+num2str(s(1),'%.2f')+newline+"score_P > 0.5: "+num2str(o5pos)+"%";
    stat_str_N = "mean_N:"+num2str(m(2),'%.2f')+newline+"std_N:"+num2str(s(2),'%.2f')+newline+"score_N < -0.5: "+num2str(o5neg)+"%";
    text(m(1),0.065,stat_str_P)
    text(m(2),0.065,stat_str_N)
    
    
    saveas(fig,sprintf('%s.jpg',opts.net.experiment_root));