function Reg= noser_image_prior( inv_model );
% NOSER_IMAGE_PRIOR calculate image prior
% Reg= noser_image_prior( inv_model )
% Reg        => output regularization term
% inv_model  => inverse model struct
%
% Prior is diag( diag(J'*J)^exponent )
% param is normally .5, this value can be changed by
% setting inv_model.noser_image_prior.exponent= new_value

% (C) 2005 Andy Adler. License: GPL version 2 or version 3
% $Id: noser_image_prior.m 3289 2012-07-01 10:40:31Z aadler $

warning('EIDORS:deprecated','NOSER_IMAGE_PRIOR is deprecated as of 08-Jun-2012. Use PRIOR_NOSER instead.');

if isfield(inv_model,'noser_image_prior');
  inv_model.prior_noser = inv_model.noser_image_prior;
end

Reg = prior_noser(inv_model);
