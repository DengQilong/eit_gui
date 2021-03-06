function [imgr, img]= compare_2d_algs(option,shape);
% Compare different 2D reconstructions
% [imgr, img]= compare_2d_algs(option);
%
% imgr - reconstructed image (256 elements)
% img  - original image      (576 elements)
%
% option -> select algorithm
% OPTION   SOLVER               PRIOR             HP
%   1   inv_solve_diff_GN_one_step       prior_laplace   1e-3
%   2   np_inv_solve       prior_laplace   1e-3
%   3   inv_solve_diff_GN_one_step       prior_gaussian_HPF   NF=2
%   3.1 inv_solve_diff_GN_one_step       prior_noser     NF=2
%   4   inv_solve_TV_pdipm   prior_TV      1e-4
%   5   aa_inv_total_var   prior_laplace   1e-4 (not the usual prior)
%   6   aa_inv_total_var   prior_TV      1e-4
%   7   aa_inv_conj_grad   prior_TV      ??? 
%   8   inv_solve_TV_irls  prior_TV      ???
%
%  OPTION = 1dd => do OPTION=dd with normalize_measurements
%
% shape
%   0  two triangles
%   1  round

% (C) 2005 Andy Adler. License: GPL version 2 or version 3
% $Id: compare_2d_algs.m 3499 2012-07-04 21:00:30Z bgrychtol $

if nargin<2
    shape=0;
end

calc_colours('ref_level','auto');

imb=  mk_common_model('c2c',16);
e= size(imb.fwd_model.elems,1);
sigma= ones(e,1);
img= eidors_obj('image','');
img.elem_data= sigma;
img.fwd_model= imb.fwd_model;
vh= fwd_solve( img );

if shape==0
    sigma([25,37,49:50,65:66,81:83,101:103,121:124])=2;
    sigma([95,98:100,79,80,76,63,64,60,48,45,36,33,22])=2;
elseif shape==1
    sigma([65,81,82,101,102,122])=2; 
elseif shape==2
    sigma(1:4)=2;
else
    error('shape not defined (%d)',shape);
end
    
img.elem_data= sigma;
vi= fwd_solve( img );

sig= sqrt(norm(vi.meas - vh.meas));
m= size(vi.meas,1);
vi.meas = vi.meas + .0001*sig*randn(m,1);
figure(2); img.elem_data= img.elem_data - 1; show_slices(img); figure(1);

%show_slices(img);
imb=  mk_common_model('b2c2',16);
inv2d= eidors_obj('inv_model', 'EIT inverse');
inv2d.reconst_type= 'difference';
inv2d.jacobian_bkgnd.value= 1;
inv2d.fwd_model= imb.fwd_model;
inv2d.fwd_model.np_fwd_solve.perm_sym= '{y}';
inv2d.parameters.term_tolerance= 1e-4;

if option>100
   inv2d.fwd_model = mdl_normalize(inv2d.fwd_model,1);
   option=option-100;
end

switch option
   case 1,
     inv2d.hyperparameter.value = 1e-3;
     inv2d.solve=       'inv_solve_diff_GN_one_step';
     inv2d.RtR_prior=   'prior_laplace';

   case 2,
     inv2d.hyperparameter.value = 1e-3;
     inv2d.RtR_prior=   'prior_laplace';
     inv2d.solve=       'np_inv_solve';

   case 3,
     inv2d.hyperparameter.func = @choose_noise_figure;
     inv2d.hyperparameter.noise_figure= 2;
     inv2d.hyperparameter.tgt_elems= 1:4;
     inv2d.RtR_prior=   'prior_gaussian_HPF';
     inv2d.solve=       'inv_solve_diff_GN_one_step';

   case 3.1,
     inv2d.hyperparameter.func = @choose_noise_figure;
     inv2d.hyperparameter.noise_figure= 2;
     inv2d.hyperparameter.tgt_elems= 1:4;
     inv2d.RtR_prior=   @prior_laplace;
     inv2d.solve=       'inv_solve_diff_GN_one_step';

   case 4,
     inv2d.hyperparameter.value = 1e-6;
     inv2d.parameters.max_iterations= 10;
     inv2d.R_prior=     'prior_TV';
     inv2d.solve=       'inv_solve_TV_pdipm';
     inv2d.parameters.keep_iterations=1;

   case 5,
     inv2d.hyperparameter.value = 1e-4;
     inv2d.solve=       'aa_inv_total_var';
     inv2d.R_prior=     'prior_laplace';
     inv2d.parameters.max_iterations= 10;

   case 6,
     subplot(141); show_slices(img);
     inv2d.hyperparameter.value = 1e-4;
     inv2d.solve=       'aa_inv_total_var';
     inv2d.R_prior=     'prior_TV';
     inv2d.parameters.max_iterations= 1;
     inv2d.parameters.keep_iterations=1;
     subplot(142); show_slices( inv_solve( inv2d, vh, vi) );
     inv2d.parameters.max_iterations= 2;                
     subplot(143); show_slices( inv_solve( inv2d, vh, vi) );
     inv2d.parameters.max_iterations= 5;                
     subplot(144); show_slices( inv_solve( inv2d, vh, vi) );
     return;

   case 7,
     inv2d.hyperparameter.value = 1e-2;
     inv2d.parameters.max_iterations = 1e3;
     inv2d.parameters.term_tolerance = 1e-3;
     inv2d.solve=          'aa_inv_conj_grad';
     inv2d.R_prior=        'prior_TV';

     
   case 8,
     inv2d.hyperparameter.value = 1e-5;
     inv2d.parameters.max_iterations= 20;
     inv2d.R_prior=     'prior_TV';
     inv2d.solve=       'inv_solve_TV_irls';
     inv2d.parameters.keep_iterations=1;
     
   otherwise,
     error('action unknown');
end

% 
% Step 3: Reconst and show image
% 
imgr= inv_solve( inv2d, vh, vi);

figure(1); show_slices(imgr);
