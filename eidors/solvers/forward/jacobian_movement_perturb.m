function J= jacobian_movement_perturb( fwd_model, img)
% JACOBIAN_MOVEMENT_PERTURB: J= jacobian_movement_perturb( img )
% Calculate Jacobian Matrix for EIT, based on conductivity
%   change and movement of electrodes
% J         = Jacobian matrix
% fwd_model = forward model
%
% fwd_model.conductivity_jacobian = fcn
%
% fwd_model.normalize_measurements if param exists, calculate
%                                  a Jacobian for normalized
%                                  difference measurements
% img = image background for jacobian calc

% (C) 2005 Andy Adler. License: GPL version 2 or version 3
% $Id: jacobian_movement_perturb.m 5196 2016-03-04 07:12:05Z alistair_boyle $

if nargin == 1
   img= fwd_model;
elseif  strcmp(getfield(warning('query','EIDORS:DeprecatedInterface'),'state'),'on')
   warning('EIDORS:DeprecatedInterface', ...
      ['Calling JACOBIAN_MOVEMENT with two arguments is deprecated and will cause' ...
       ' an error in a future version. First argument ignored.']);
   warning off EIDORS:DeprecatedInterface

end
fwd_model= img.fwd_model;

pp= fwd_model_parameters( fwd_model, 'skip_VOLUME' );
delta= 1e-6; % tests indicate this is a good value
             % too high and J is not linear, too low and numerical error

if isfield(fwd_model,'conductivity_jacobian')
   % reroute the calculation through calc_jacobian to correctly process
   % eidors_default
   tmp = img;
   tmp.fwd_model = rmfield(tmp.fwd_model,'conductivity_jacobian');
   tmp.fwd_model.jacobian = fwd_model.conductivity_jacobian;
   Jc = calc_jacobian(tmp);
%    Jc= feval(fwd_model.conductivity_jacobian, fwd_model, img );
else
   fwd_model.jacobian_perturb.delta = delta;
   fwd_model = mdl_normalize(fwd_model,0); % we normalize on our own
   Jc = jacobian_perturb(fwd_model, img);
%    Jc= conductivity_jacobian_perturb( pp, delta, img );
end

Jm= movement_jacobian( pp, delta, img );
J= [Jc,Jm];

% calculate normalized Jacobian
if pp.normalize
   data= fwd_solve( img );
   J= J ./ (data.meas(:)*ones(1,size(J,2)));
end


% Calculate the conductivity jacobian based on a perturbation
% of each element by a delta 
% Relative error mean(mean(abs(J-Jx)))/ mean(mean(abs(J)))
%   10^-2   0.00308129369015
%   10^-3   0.00030910899216
%   10^-4   0.00003092078190
%   10^-5   0.00000309281790
%   10^-6   0.00000035468582
%   10^-7   0.00000098672198
%   10^-8   0.00000938262464
%   10^-9   0.00009144743903

function J= conductivity_jacobian_perturb( pp, delta, img );

J = zeros( pp.n_meas, pp.n_elem );

elem_data = img.elem_data;
d0= fwd_solve( img );
for i=1:pp.n_elem
   img.elem_data   = elem_data;
   img.elem_data(i)= elem_data(i) + delta;
   di= fwd_solve( img );
   J(:,i) = (1/delta) * (di.meas - d0.meas);
end

% xy-Movement Jacobian
function J= movement_jacobian( pp, delta, img )

J = zeros( pp.n_meas, pp.n_elec*pp.n_dims );

node0= img.fwd_model.nodes;
d0= fwd_solve( img );
for d= 1:pp.n_dims
   for i= 1:pp.n_elec
      idx= img.fwd_model.electrode(i).nodes;

      img.fwd_model.nodes( idx, d)= node0(idx,d) + delta;
      di= fwd_solve( img );
      img.fwd_model.nodes( idx, d)= node0(idx,d);

      J_idx = pp.n_elec*(d-1) + i;
      J(:,J_idx) = (1/delta) * (di.meas - d0.meas);
   end
end
