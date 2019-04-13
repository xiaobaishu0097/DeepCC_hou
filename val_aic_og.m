clear
clc

%% Options
opts = get_opts_aic();
opts.experiment_name = 'aic_og';
opts.feature_dir = 'det_features_ide_basis_train_10fps_5e-2_trainval';
% basis setting for DeepCC
opts.tracklets.window_width = 10;
opts.trajectories.window_width = 20;
opts.trajectories.overlap = 10;
opts.identities.window_width = 200;
% correlation threshold setting according to `view_distance_distribution(opts)`
opts.tracklets.threshold    = 12.02;
opts.trajectories.threshold = 12.02;
opts.identities.threshold   = 12.02;

opts.tracklets.diff_p    = 7.66;
opts.trajectories.diff_p = 7.66;
opts.identities.diff_p   = 7.66;
opts.tracklets.diff_n    = 7.66;
opts.trajectories.diff_n = 7.66;
opts.identities.diff_n   = 7.66;

% alpha
opts.tracklets.alpha    = 0;
opts.trajectories.alpha = 0;
opts.identities.alpha   = 0;

% loss
opts.trajectories.og_smoothness_score = 1;
opts.trajectories.og_velocity_change_score = 1;
opts.trajectories.og_time_interval_score = 1;

% weights
opts.trajectories.weightAppearance = 1;
opts.trajectories.weightSmoothness = 0.1;
opts.trajectories.weightVelocityChange = 0.15;
opts.trajectories.weightTimeInterval = 0.2;

create_experiment_dir(opts);
%% Setup Gurobi
if ~exist('setup_done','var')
    setup;
    setup_done = true;
end

%% Run Tracker
opts.visualize = false;
opts.sequence = 8;

if opts.sequence == 6
    opts.scene_by_icam = [1, 1, 1, 1, 1, 2, 2, 2, 2, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];
end

% Tracklets
opts.tracklets.spatial_groups = 0;
opts.optimization = 'KL';
compute_L1_tracklets_aic(opts);

% Single-camera trajectories
opts.optimization = 'KL';
%opts.trajectories.use_indiff = false;
opts.experiment_name = 'aic_og';
opts.trajectories.appearance_groups = 1;
compute_L2_trajectories_aic(opts);
opts.eval_dir = 'L2-trajectories';
evaluate(opts);

% Multi-camera identities
% opts.optimization = 'BIPCC';
opts.identities.optimal_filter = false;
opts.identities.consecutive_icam_matrix = ones(40);
opts.identities.reintro_time_matrix = ones(1,40)*inf;
opts.identities.appearance_groups = 0;
compute_L3_identities_aic(opts);
opts.eval_dir = 'L3-identities';
evaluate(opts);
