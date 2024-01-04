function [MuscleData] = muscleAnalysisAPI(S,osim_path,model_info,varargin)
% --------------------------------------------------------------------------
% muscleAnalysisAPI
%   Analyse the musculoskeletal geometry of the given osim model.
% 
% INPUT:
%   - S -
%   * setting structure S
%
%   - osim_path -
%   * path to the OpenSim model file (.osim)
% 
%   - model_info -
%   * structure with all the model information based on the OpenSim model
%
%   - Qs - (Optional input, for testing purpose)
%   * Known array with coordinate values used to perform muscle analysis.
%   When omitted, a random array is generated by "PreProcessing\generate_dummy_motion"
%
%   - analyse_ligaments (Optional input)-
%   * Pass argument 'ligaments' to analyse ligaments instead of
%   muscle-tendon paths
%
% OUTPUT:
%   - MuscleData -
%   * structure with joint angles and according muscle-tendon lengths and
%   momentarms (input to PolynomialFit.m)
%
% Original author: Lars D'Hondt
% Original date: 5/April/2022
%
% Last edit by:
% Last edit date:
% --------------------------------------------------------------------------



% number of coordinates
n_coord = model_info.ExtFunIO.jointi.nq.all;
% coordinate names
coord_names = model_info.ExtFunIO.coord_names.all;

% names of muscles
muscle_names = model_info.muscle_info.muscle_names;
% number of muscles
n_muscle = model_info.muscle_info.NMuscle;
% get senseble muscle-coordinate combinations to evaluate
muscle_spanning_joint_info = model_info.muscle_info.muscle_spanning_joint_info;

if contains(varargin(isa(varargin,'char') | isa(varargin,'string')),'ligaments')
    muscle_names = model_info.ligament_info.ligament_names;
    n_muscle = model_info.ligament_info.NLigament;
    muscle_spanning_joint_info = model_info.ligament_info.ligament_spanning_joint_info;
    ligaments_bool = 1;
    varargin = varargin(2:end);
else
    ligaments_bool = 0;
end

if length(varargin)>=1
    argin3 = varargin{1};

    if size(argin3,1) == 1 && size(argin3,2) == 1
        % if it's 1 element, it's the number of data points
        n_data_points = argin3;
    else
        % else, it's the entire dummy motion
        Qs = argin3;
        % number of data points
        n_data_points = size(Qs,1);
    end
else
    % number of data points
    n_data_points = S.misc.msk_geom_n_samples;
    % get dummy motion
    Qs = generate_dummy_motion(S,model_info,n_data_points);
end

%% Initialise model
import org.opensim.modeling.*;
model = Model(osim_path);
s = model.initSystem;
% Get state vector
state_vars = model.getStateVariableValues(s);
% Get set of muscles and other forces
if ligaments_bool
    force_set = model.getForceSet();
else
    force_set = model.getMuscles();
end

%% Evaluate muscle-tendon unit lenght and moment arms
% Set state vector to 0
state_vars.setToZero();
model.setStateVariableValues(s,state_vars);
model.realizePosition(s);

% Initialise matrices for results
lMT = zeros(n_data_points,n_muscle);
dM = zeros(n_data_points,n_muscle,n_coord);

% Loop through dummy states
for j=1:n_data_points
    % Set each coordinate value
    for i=1:n_coord
        state_vars.set(model_info.ExtFunIO.coordi_OpenSimAPIstate.(coord_names{i}),Qs(j,i));
    end
    model.setStateVariableValues(s,state_vars);
    model.realizePosition(s);

    % Loop over muscles
    for m=1:n_muscle
        muscle_m = force_set.get(muscle_names{m});
        if ligaments_bool
            muscle_m = Ligament.safeDownCast(muscle_m);
        end
        % Get MTU length
        lMT(j,m) = muscle_m.getLength(s);
        % Get moment arm for each joint
        for i=1:n_coord
            if muscle_spanning_joint_info(m,i)
                dM(j,m,i) = muscle_m.computeMomentArm(s,model.getCoordinateSet().get(coord_names{i}));
            end
        end
    end

end


%% Store analysis results
% structure and fieldnames of MuscleData are to be consistent with PolynomialFit.m

% coordinate names
MuscleData.dof_names = model_info.ExtFunIO.coord_names.all;
% muscle names
MuscleData.muscle_names = muscle_names;
% joint angles training data
MuscleData.q = Qs;
% muscle-tendon lengths
MuscleData.lMT = lMT;
% moment arms
MuscleData.dM = dM;







