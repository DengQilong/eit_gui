function J= jacobian_filtered( fwd_model, img)
% JACOBIAN_FILTERED: J= jacobian_filtered( fwd_model, img)
%
% Filter a jacobian matrix by a specified filter function
% INPUT:
%  fwd_model = forward model
%  fwd_model.jacobian_filtered.jacobian = actual jacobian function (J0)
%  fwd_model.jacobian_filtered.filter   = Filter Matrix (F)
%  img = image background for jacobian calc
% OUTPUT:
%  J         = Jacobian matrix = F*J0

% (C) 2009 Andy Adler. License: GPL version 2 or version 3
% $Id: jacobian_filtered.m 3101 2012-06-08 14:34:08Z bgrychtol $

J0 = feval(fwd_model.jacobian_filtered.jacobian, ...
           fwd_model, img);
F  = fwd_model.jacobian_filtered.filter;

J= F*J0;

