# -*- coding: utf-8 -*-
import os

components_definition = [
    ('development', {
        'components': [
            ['neuro-forge', {
                'branches': {
                    'trunk': ('git https://github.com/neurospin/neuro-forge.git branch:main','development/neuro-forge/integration'),
                    'bug_fix': ('git https://github.com/neurospin/neuro-forge.git branch:main','development/neuro-forge/master'),
                    '5.1': ('git https://github.com/neurospin/neuro-forge.git branch:main','development/neuro-forge/5.1'),
                },
            }],
            ['brainvisa-cmake', {
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/brainvisa-cmake.git branch:master','development/brainvisa-cmake/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/brainvisa-cmake.git branch:master','development/brainvisa-cmake/master'),
                    '5.0': ('git https://github.com/brainvisa/brainvisa-cmake.git branch:5.0','development/brainvisa-cmake/5.0'),
                    '5.1': ('git https://github.com/brainvisa/brainvisa-cmake.git branch:5.1','development/brainvisa-cmake/5.1'),
                },
            }],
            ['casa-distro', {
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/casa-distro.git branch:master','development/casa-distro/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/casa-distro.git branch:master','development/casa-distro/master'),
                    '5.0': ('git https://github.com/brainvisa/casa-distro.git branch:brainvisa-5.0','development/casa-distro/5.0'),
                    '5.1': ('git https://github.com/brainvisa/casa-distro.git branch:brainvisa-5.1','development/casa-distro/5.1'),
                },
                'build_model': 'pure_python',
            }],
        ],
    }),
    ('communication', {
        'components': [
            ['web', {
                'branches': {
                    'trunk': ('git https://bioproj.extra.cea.fr/git/brainvisa-commu/web.git branch:integration','communication/web/trunk'),
                    'bug_fix': ('git https://bioproj.extra.cea.fr/git/brainvisa-commu/web.git branch:master','communication/web/master'),
                    '5.0': ('git https://bioproj.extra.cea.fr/git/brainvisa-commu/web.git branch:master','communication/web/5.0'),
                    '5.1': ('git https://bioproj.extra.cea.fr/git/brainvisa-commu/web.git branch:master','communication/web/5.1'),
                },
            }],
        ],
    }),
    ('brainvisa-share', {
        'components': [
            ['brainvisa-share', {
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/brainvisa-share.git branch:master','brainvisa-share/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/brainvisa-share.git branch:master','brainvisa-share/master'),
                    '5.0': ('git https://github.com/brainvisa/brainvisa-share.git branch:5.0','brainvisa-share/5.0'),
                    '5.1': ('git https://github.com/brainvisa/brainvisa-share.git branch:5.1','brainvisa-share/5.1'),
                },
            }],
        ],
    }),
    ('soma', {
        'components': [
            ['soma-base', {
                'branches': {
                    'trunk': ('git https://github.com/populse/soma-base.git branch:master','soma/soma-base/integration'),
                    'bug_fix': ('git https://github.com/populse/soma-base.git branch:master','soma/soma-base/master'),
                    '5.0': ('git https://github.com/populse/soma-base.git branch:5.0','soma/soma-base/5.0'),
                    '5.1': ('git https://github.com/populse/soma-base.git branch:5.1','soma/soma-base/5.1'),
                },
            }],
            ['soma-io', {
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/soma-io.git branch:master','soma/soma-io/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/soma-io.git branch:master','soma/soma-io/master'),
                    '5.0': ('git https://github.com/brainvisa/soma-io.git branch:5.0','soma/soma-io/5.0'),
                    '5.1': ('git https://github.com/brainvisa/soma-io.git branch:5.1','soma/soma-io/5.1'),
                },
            }],
            ['soma-workflow', {
                'branches': {
                    'trunk': ('git https://github.com/populse/soma-workflow.git branch:master','soma/soma-workflow/integration'),
                    'bug_fix': ('git https://github.com/populse/soma-workflow.git default:master','soma/soma-workflow/master'),
                    '5.0': ('git https://github.com/populse/soma-workflow.git branch:brainvisa-5.0','soma/soma-workflow/5.0'),
                    '5.1': ('git https://github.com/populse/soma-workflow.git branch:brainvisa-5.1','soma/soma-workflow/5.1'),
                },
            }],
        ],
    }),
    ('populse', {
        'components': [
            ['capsul', {
                'branches': {
                    'trunk': ('git https://github.com/populse/capsul.git branch:master','capsul/integration'),
                    'bug_fix': ('git https://github.com/populse/capsul.git default:master','capsul/master'),
                    '5.0': ('git https://github.com/populse/capsul.git branch:brainvisa-5.0','capsul/5.0'),
                    '5.1': ('git https://github.com/populse/capsul.git branch:brainvisa-5.1','capsul/5.1'),
                },
                'build_model': 'pure_python',
            }],
            ['populse-db', {
                'branches': {
                    'trunk': ('git https://github.com/populse/populse_db.git default:master','populse/populse_db/integration'),
                    'bug_fix': ('git https://github.com/populse/populse_db.git default:master','populse/populse_db/master'),
                    '5.0': ('git https://github.com/populse/populse_db.git branch:brainvisa-5.0','populse/populse_db/5.0'),
                    '5.1': ('git https://github.com/populse/populse_db.git branch:brainvisa-5.1','populse/populse_db/5.1'),
                },
                'build_model': 'pure_python',
            }],
        ],
    }),
    ('aims', {
        'components': [
            ['aims-free', {
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/aims-free.git branch:master','aims/aims-free/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/aims-free.git branch:master','aims/aims-free/master'),
                    '5.0': ('git https://github.com/brainvisa/aims-free.git branch:5.0','aims/aims-free/5.0'),
                    '5.1': ('git https://github.com/brainvisa/aims-free.git branch:5.1','aims/aims-free/5.1'),
                },
            }],
            ['aims-gpl', {
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/aims-gpl.git branch:master','aims/aims-gpl/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/aims-gpl.git branch:master','aims/aims-gpl/master'),
                    '5.0': ('git https://github.com/brainvisa/aims-gpl.git branch:5.0','aims/aims-gpl/5.0'),
                    '5.1': ('git https://github.com/brainvisa/aims-gpl.git branch:5.1','aims/aims-gpl/5.1'),
                },
            }],
            ['aims-til', {
                'branches': {
                    '5.0': ('git https://github.com/brainvisa/aims-til.git branch:5.0','aims/aims-til/5.0'),
                },
            }],
        ],
    }),
    ('anatomist', {
        'components': [
            ['anatomist-free', {
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/anatomist-free.git branch:master','anatomist/anatomist-free/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/anatomist-free.git branch:master','anatomist/anatomist-free/master'),
                    '5.0': ('git https://github.com/brainvisa/anatomist-free.git branch:5.0','anatomist/anatomist-free/5.0'),
                    '5.1': ('git https://github.com/brainvisa/anatomist-free.git branch:5.1','anatomist/anatomist-free/5.1'),
                },
            }],
            ['anatomist-gpl', {
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/anatomist-gpl.git branch:master','anatomist/anatomist-gpl/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/anatomist-gpl.git branch:master','anatomist/anatomist-gpl/master'),
                    '5.0': ('git https://github.com/brainvisa/anatomist-gpl.git branch:5.0','anatomist/anatomist-gpl/5.0'),
                    '5.1': ('git https://github.com/brainvisa/anatomist-gpl.git branch:5.1','anatomist/anatomist-gpl/5.1'),
                },
            }],
        ],
    }),
    ('axon', {
        'components': [
            ['axon', {
                'about': {
                    'summary': 'Axon organizes processing, pipelining, and data management for neuroimaging. It works both as a graphical user interface or batch and programming interfaces, and allows transparent processing distribution on a computing resource.',
                },
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/axon.git branch:master','axon/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/axon.git branch:master','axon/master'),
                    '5.0': ('git https://github.com/brainvisa/axon.git branch:5.0','axon/5.0'),
                    '5.1': ('git https://github.com/brainvisa/axon.git branch:5.1','axon/5.1'),
                },
            }],
        ],
    }),
    ('brainvisa-spm', {
        'packages': ['anatomist'],
        'components': [
            ['brainvisa-spm', {
                'about': {
                    'summary': 'Python module and Axon toolbox for SPM.',
                },
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/brainvisa-spm.git branch:integration','brainvisa-spm/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/brainvisa-spm.git branch:master','brainvisa-spm/master'),
                    '5.0': ('git https://github.com/brainvisa/brainvisa-spm.git branch:5.0','brainvisa-spm/5.0'),
                    '5.1': ('git https://github.com/brainvisa/brainvisa-spm.git branch:5.1','brainvisa-spm/5.1'),
                },
            }],
        ],
    }),
    ('datamind', {
        'components': [
            ['datamind', {
                'about': {
                    'summary': 'Statistics, data mining, machine learning [OBSOLETE].',
                },
                'branches': {
                    '5.0': ('svn https://bioproj.extra.cea.fr/neurosvn/brainvisa/datamind/branches/5.0','datamind/5.0'),
                },
            }],
        ],
    }),

    ('highres-cortex', {
        'components': [
            ['highres-cortex', {
                'about': {
                    'summary': 'Process 3D images of the cerebral cortex at a sub-millimetre scale',
                },
                'branches': {
                    'trunk': ('git https://github.com/neurospin/highres-cortex.git branch:master','highres-cortex/integration'),
                    'bug_fix': ('git https://github.com/neurospin/highres-cortex.git default:master','highres-cortex/master'),
                    '5.0': ('git https://github.com/neurospin/highres-cortex.git branch:5.0','highres-cortex/5.0'),
                    '5.1': ('git https://github.com/neurospin/highres-cortex.git branch:5.1','highres-cortex/5.1'),
                },
            }],
        ],
    }),

    ('morphologist', {
        'components': [
            ['morphologist-nonfree', {
                'about': {
                    'summary': 'Non open source component of brainvisa-morphologist package',
                },
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/morphologist-nonfree.git branch:integration','morphologist/morphologist-nonfree/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/morphologist-nonfree.git branch:master','morphologist/morphologist-nonfree/master'),
                    '5.0': ('git https://github.com/brainvisa/morphologist-nonfree.git branch:5.0','morphologist/morphologist-nonfree/5.0'),
                    '5.1': ('git https://github.com/brainvisa/morphologist-nonfree.git branch:5.1','morphologist/morphologist-nonfree/5.1'),
                },
            }],
            ['morphologist-gpl', {
                'about': {
                    'summary': 'GPL licensed component of brainvisa-morphologist package',
                },
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/morphologist-gpl.git branch:integration','morphologist/morphologist-gpl/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/morphologist-gpl.git branch:master','morphologist/morphologist-gpl/master'),
                    '5.0': ('git https://github.com/brainvisa/morphologist-gpl.git branch:5.0','morphologist/morphologist-gpl/5.0'),
                    '5.1': ('git https://github.com/brainvisa/morphologist-gpl.git branch:5.1','morphologist/morphologist-gpl/5.1'),
                },
            }],
            ['morphologist-baby', {
                'about': {
                    'summary': 'Human baby brain analysis component of brainvisa-morphologist package',
                },
                'branches': {
                    'trunk': ('git https://bioproj.extra.cea.fr/git/brainvisa-t1mri/morphologist-baby.git branch:integration','morphologist/morphologist-baby/integration'),
                    'bug_fix': ('git https://bioproj.extra.cea.fr/git/brainvisa-t1mri/morphologist-baby.git branch:master','morphologist/morphologist-baby/master'),
                    '5.0': ('git https://bioproj.extra.cea.fr/git/brainvisa-t1mri/morphologist-baby.git branch:5.0','morphologist/morphologist-baby/5.0'),
                    '5.1': ('git https://bioproj.extra.cea.fr/git/brainvisa-t1mri/morphologist-baby.git branch:5.1','morphologist/morphologist-baby/5.1'),
                },
            }],
            ['tms', {
                'branches': {
                },
            }],
            ['sulci-data', {
                'about': {
                    'summary': 'data component of brainvisa-morphologist package',
                },
                'branches': {
                    'trunk': ('svn https://bioproj.extra.cea.fr/neurosvn/brainvisa/morphologist/sulci-data/trunk','morphologist/sulci-data/trunk'),
                    'bug_fix': ('svn https://bioproj.extra.cea.fr/neurosvn/brainvisa/morphologist/sulci-data/trunk','morphologist/sulci-data/bug_fix'),
                },
            }],
            ['sulci-nonfree', {
                'about': {
                    'summary': 'Initial sulci analysis component of brainvisa-morphologist package',
                },
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/sulci-nonfree.git branch:integration','morphologist/sulci-nonfree/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/sulci-nonfree.git branch:master','morphologist/sulci-nonfree/master'),
                    '5.0': ('git https://github.com/brainvisa/sulci-nonfree.git branch:5.0','morphologist/sulci-nonfree/5.0'),
                    '5.1': ('git https://github.com/brainvisa/sulci-nonfree.git branch:5.1','morphologist/sulci-nonfree/5.1'),
                },
            }],
            ['morphologist-ui', {
                'about': {
                    'summary': 'Alternative graphical interface for brainvisa-morphologist package',
                },
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/morphologist.git branch:master', 'morphologist/morphologist-ui/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/morphologist.git default:master', 'morphologist/morphologist-ui/master'),
                    '5.0': ('git https://github.com/brainvisa/morphologist.git branch:5.0', 'morphologist/morphologist-ui/5.0'),
                    '5.1': ('git https://github.com/brainvisa/morphologist.git branch:5.1', 'morphologist/morphologist-ui/5.1'),
                },
            }],
            ['morpho-deepsulci', {
                'about': {
                    'summary': 'Deep learnig based sulci analysis component of brainvisa-morphologist package',
                },
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/morpho-deepsulci.git branch:master', 'morphologist/morpho-deepsulci/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/morpho-deepsulci.git default:master', 'morphologist/morpho-deepsulci/master'),
                    '5.0': ('git https://github.com/brainvisa/morpho-deepsulci.git branch:5.0', 'morphologist/morpho-deepsulci/5.0'),
                    '5.1': ('git https://github.com/brainvisa/morpho-deepsulci.git branch:5.1', 'morphologist/morpho-deepsulci/5.1'),
                },
            }],
        ],
    }),
    ('brainrat', {
        'components': [
            ['brainrat-gpl', {
                'branches': {
                    'trunk': ('git https://bioproj.extra.cea.fr/git/brainrat-gpl branch:master', 'brainrat/brainrat-gpl/integration'),
                    'bug_fix': ('git https://bioproj.extra.cea.fr/git/brainrat-gpl branch:master', 'brainrat/brainrat-gpl/master'),
                    '5.0': ('git https://bioproj.extra.cea.fr/git/brainrat-gpl branch:5.0', 'brainrat/brainrat-gpl/5.0'),
                    '5.1': ('git https://bioproj.extra.cea.fr/git/brainrat-gpl branch:5.1', 'brainrat/brainrat-gpl/5.1'),
                },
            }],
            ['brainrat-private', {
                'branches': {
                    'trunk': ('git https://bioproj.extra.cea.fr/git/brainrat-private branch:master', 'brainrat/brainrat-private/integration'),
                    'bug_fix': ('git https://bioproj.extra.cea.fr/git/brainrat-private branch:master', 'brainrat/brainrat-private/master'),
                    '5.0': ('git https://bioproj.extra.cea.fr/git/brainrat-private branch:5.0', 'brainrat/brainrat-private/5.0'),
                    '5.1': ('git https://bioproj.extra.cea.fr/git/brainrat-private branch:5.1', 'brainrat/brainrat-private/5.1'),
                },
            }],
            ['bioprocessing', {
                'branches': {
                    'trunk': ('git https://bioproj.extra.cea.fr/git/bioprocessing branch:master', 'brainrat/bioprocessing/integration'),
                    'bug_fix': ('git https://bioproj.extra.cea.fr/git/bioprocessing branch:master', 'brainrat/bioprocessing/master'),
                    '5.0': ('git https://bioproj.extra.cea.fr/git/bioprocessing branch:5.0', 'brainrat/bioprocessing/5.0'),
                    '5.1': ('git https://bioproj.extra.cea.fr/git/bioprocessing branch:5.1', 'brainrat/bioprocessing/5.1'),
                },
            }],
            ['preclinical-imaging-iam', {
                'branches': {
                    'trunk': ('git https://bioproj.extra.cea.fr/git/preclinical-imaging-iam branch:master', 'brainrat/preclinical-imaging-iam/integration'),
                    'bug_fix': ('git https://bioproj.extra.cea.fr/git/preclinical-imaging-iam branch:master', 'brainrat/preclinical-imaging-iam/master'),
                },
            }],
            ['primatologist-gpl', {
                'branches': {
                    'trunk': ('git https://bioproj.extra.cea.fr/git/primatologist-gpl branch:master', 'brainrat/primatologist-gpl/integration'),
                    'bug_fix': ('git https://bioproj.extra.cea.fr/git/primatologist-gpl branch:master', 'brainrat/primatologist-gpl/master'),
                    '5.0': ('git https://bioproj.extra.cea.fr/git/primatologist-gpl branch:5.0', 'brainrat/primatologist-gpl/5.0'),
                    '5.1': ('git https://bioproj.extra.cea.fr/git/primatologist-gpl branch:5.1', 'brainrat/primatologist-gpl/5.1'),
                },
            }],
            ['3dns-private', {
                'branches': {
                    'trunk': ('git https://bioproj.extra.cea.fr/git/3dns-private branch:master', 'brainrat/3dns-private/integration'),
                    'bug_fix': ('git https://bioproj.extra.cea.fr/git/3dns-private branch:master', 'brainrat/3dns-private/master'),
                    '5.0': ('git https://bioproj.extra.cea.fr/git/3dns-private branch:5.0', 'brainrat/3dns-private/5.0'),
                    '5.1': ('git https://bioproj.extra.cea.fr/git/3dns-private branch:master', 'brainrat/3dns-private/5.1'),
                },
            }],
        ],
    }),
    ('constellation', {
        'components': [
            ['constellation-gpl', {
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/constellation-gpl.git branch:integration','constellation/constellation-gpl/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/constellation-gpl.git branch:master','constellation/constellation-gpl/master'),
                    '5.0': ('git https://github.com/brainvisa/constellation-gpl.git branch:5.0','constellation/constellation-gpl/5.0'),
                    '5.1': ('git https://github.com/brainvisa/constellation-gpl.git branch:5.1','constellation/constellation-gpl/5.1'),
                },
            }],
            ['constellation-nonfree', {
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/constellation-nonfree.git branch:integration','constellation/constellation-nonfree/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/constellation-nonfree.git branch:master','constellation/constellation-nonfree/master'),
                    '5.0': ('git https://github.com/brainvisa/constellation-nonfree.git branch:5.0','constellation/constellation-nonfree/5.0'),
                    '5.1': ('git https://github.com/brainvisa/constellation-nonfree.git branch:5.1','constellation/constellation-nonfree/5.1'),
                },
            }],
        ],
    }),
    ('cortical_surface', {
        'components': [
            ['cortical_surface-nonfree', {
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/cortical_surface-nonfree.git branch:integration','cortical_surface/cortical_surface-nonfree/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/cortical_surface-nonfree.git branch:master','cortical_surface/cortical_surface-nonfree/master'),
                    '5.0': ('git https://github.com/brainvisa/cortical_surface-nonfree.git branch:5.0','cortical_surface/cortical_surface-nonfree/5.0'),
                    '5.1': ('git https://github.com/brainvisa/cortical_surface-nonfree.git branch:5.1','cortical_surface/cortical_surface-nonfree/5.1'),
                },
            }],
            ['cortical_surface-gpl', {
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/cortical_surface-gpl.git branch:integration','cortical_surface/cortical_surface-gpl/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/cortical_surface-gpl.git branch:master','cortical_surface/cortical_surface-gpl/master'),
                    '5.0': ('git https://github.com/brainvisa/cortical_surface-gpl.git branch:5.0','cortical_surface/cortical_surface-gpl/5.0'),
                    '5.1': ('git https://github.com/brainvisa/cortical_surface-gpl.git branch:5.1','cortical_surface/cortical_surface-gpl/5.1'),
                },
            }],
            ['brainvisa_freesurfer', {
                'branches': {
                    'trunk': ('git https://github.com/brainvisa/brainvisa_freesurfer.git branch:integration','cortical_surface/brainvisa_freesurfer/integration'),
                    'bug_fix': ('git https://github.com/brainvisa/brainvisa_freesurfer.git branch:master','cortical_surface/brainvisa_freesurfer/master'),
                    '5.0': ('git https://github.com/brainvisa/brainvisa_freesurfer.git branch:5.0','cortical_surface/brainvisa_freesurfer/5.0'),
                    '5.1': ('git https://github.com/brainvisa/brainvisa_freesurfer.git branch:5.1','cortical_surface/brainvisa_freesurfer/5.1'),
                },
            }],
        ],
    }),
    ('nuclear_imaging', {
        'components': [
            ['nuclear_imaging-gpl', {
                'branches': {
                    'bug_fix': ('git https://github.com/cati-neuroimaging/nuclear_imaging-gpl.git branch:master','nuclear_imaging/nuclear_imaging-gpl/master'),
                    '5.0': ('git https://github.com/cati-neuroimaging/nuclear_imaging-gpl.git branch:5.0','nuclear_imaging/nuclear_imaging-gpl/5.0'),
                    '5.1': ('git https://github.com/cati-neuroimaging/nuclear_imaging-gpl.git branch:5.1','nuclear_imaging/nuclear_imaging-gpl/5.1'),
                },
            }],
            ['nuclear_imaging-nonfree', {
                'branches': {
                    'bug_fix': ('git https://github.com/cati-neuroimaging/nuclear_imaging-nonfree.git branch:master','nuclear_imaging/nuclear_imaging-nonfree/master'),
                    '5.0': ('git https://github.com/cati-neuroimaging/nuclear_imaging-nonfree.git branch:5.0','nuclear_imaging/nuclear_imaging-nonfree/5.0'),
                    '5.1': ('git https://github.com/cati-neuroimaging/nuclear_imaging-nonfree.git branch:5.1','nuclear_imaging/nuclear_imaging-nonfree/5.1'),
                },
            }],
        ],
    }),
    ('snapbase', {
        'components': [
            ['snapbase', {
                'branches': {
                    '5.0': ('svn https://bioproj.extra.cea.fr/neurosvn/brainvisa/snapbase/branches/5.0','snapbase/5.0'),
                },
            }],
        ],
    }),
    ('catidb', {
        'components': [
            ['catidb-client', {
                'branches': {
                    'bug_fix': ('git https://github.com/cati-neuroimaging/catidb-client.git default:main', 'catidb-client'),
                },
            }],
        ],
    }),
    ('sacha', {
        'components': [
            ['sacha-nonfree', {
                'branches': {
                    'bug_fix': ('git https://github.com/cati-neuroimaging/sacha-nonfree.git branch:master', 'sacha-nonfree/master'),
                },
            }],
            ['sacha-gpl', {
                'branches': {
                    'bug_fix': ('git https://github.com/cati-neuroimaging/sacha-gpl.git branch:master', 'sacha-gpl/master'),
                },
            }],
        ],
    }),
    ('whasa', {
        'components': [
            ['whasa-nonfree', {
                'branches': {
                    'bug_fix': ('git https://github.com/cati-neuroimaging/whasa-nonfree.git branch:master', 'whasa-nonfree/master'),
                },
            }],
            ['whasa-gpl', { # Experimental branch to propose a new organization
                'branches': {
                    'bug_fix': ('git https://github.com/cati-neuroimaging/whasa-gpl.git branch:master', 'whasa-gpl/master'),
                    },
            }],
        ],
    }),
    ('longitudinal_pipelines', {
        'components': [
            ['longitudinal_pipelines', {
                'branches': {
                    'bug_fix': ('git https://github.com/cati-neuroimaging/longitudinal_pipelines.git branch:master',
                              'longitudinal_pipelines/master'),
                    '5.0': ('git https://github.com/cati-neuroimaging/longitudinal_pipelines.git branch:5.0',
                              'longitudinal_pipelines/5.0'),
                    '5.1': ('git https://github.com/cati-neuroimaging/longitudinal_pipelines.git branch:5.1',
                              'longitudinal_pipelines/5.1'),
                },
            }],
        ],
    }),
    ('disco', {
        'components': [
            ['disco', {
                'branches': {
                    'trunk': ('git https://bioproj.extra.cea.fr/git/brainvisa-disco branch:master', 'disco/integration'),
                    'bug_fix': ('git https://bioproj.extra.cea.fr/git/brainvisa-disco branch:master', 'disco/master'),
                    '5.0': ('git https://bioproj.extra.cea.fr/git/brainvisa-disco branch:5.0', 'disco/5.0'),
                    '5.1': ('git https://bioproj.extra.cea.fr/git/brainvisa-disco branch:5.1', 'disco/5.1'),
                },
            }],
        ],
    }),
    ('qualicati', {
        'components': [
            ['qualicati', {
                'branches': {
                    'bug_fix': ('git https://github.com/cati-neuroimaging/qualicati.git default:main', 'qualicati'),
                },
                'build_model': 'pure_python',
            }],
        ],
    }),
    ('deidentification', {
        'components': [
            ['deidentification', {
                'branches': {
                    'bug_fix': ('git https://github.com/cati-neuroimaging/deidentification.git default:master', 'deidentification'),
                },
            }],
        ],
    }),
    ('fmri', {
        'about': {
            'summary': 'Functional MRI processing toolboxes.',
        },
        'components': [
            ['rsfmri', {
                'branches': {
                    'bug_fix': ('git https://github.com/cati-neuroimaging/rsfmri.git branch:master','rsfmri/master'),
                },
                'build_model': 'pure_python',
            }],
        ],
    }),
]

packages_definition = {
    'brainvisa-base': {
        'alias': 'base',
        'about': {
            'summary': 'Software base infrastructure for BrainVISA tools.',
            'license': 'GPL',
        },
        'packages': {
            'brainvisa-cmake',
            'neuro-forge',
            'capsul',
            'casa-distro',
            'populse-db',
            'soma-base',
            'soma-io',
            'soma-workflow'}
    },

    'brainvisa-data-processing': {
        'alias': ['data-processing', 'core'],
        'about': {
            'summary': 'Data readers/writers and processing tools in C++ and Python.',
            'license': 'GPL',
        },
        'packages': {
            'brainvisa-base',
            'aims-free',
            'aims-gpl',
            'axon',
            'brainvisa-share',
        },
    },

    'anatomist': {
        'about': {
            'summary': '3D/4D neuroimaging data viewer of the BrainVISA project. Modular and versatile, Anatomist can display any kind of neuroimaging data (3D/4D images, meshes and textures, fiber tracts, and structured sets of objects such as cortical sulci), in an arbitrary number of views. Allows C++ and Python programming, both for plugins add-ons, as well as complete custom graphical applications design.',
            'license': 'CeCILL',
        },
        'packages': {
            'brainvisa-data-processing',
            'anatomist-free',
            'anatomist-gpl'
        }
    },

    'brainvisa-disco': {
        'alias': 'disco',
        'about': {
            'summary': 'Neuroimaging method for cross-subject brain alignment.',
            'license': 'GPL',
        },
        'packages': {
            'anatomist',
            'brainvisa-spm',
            'disco',
        }
    },

    'brainvisa-freesurfer': {
        'alias': 'freesurfer',
        'about': {
            'summary': 'Links between Freesurfer and BrainVISA.',
            'license': 'GPL',
        },
        'packages': {
            'anatomist',
            'brainvisa_freesurfer',
        }
    },

    'brainvisa-highres-cortex': {
        'alias': 'highres-cortex',
        'about': {
            'summary': 'Analysis of the laminar structure of the cortex in high resolution MRI.',
            'license': 'GPL',
        },
        'packages': {
            'anatomist',
            'highres-cortex',
        }
    },

    'morphologist': {
        'about': {
            'summary': 'Anatomical MRI (T1) analysis toolbox, featuring cortex and sulci segmentation as well as sulci analysis tools.',
            'license': 'GPL',
        },
        'packages': {
            'anatomist',
            'morpho-deepsulci',
            'morphologist-ui',
            'morphologist-gpl',
            'morphologist-nonfree',
            'sulci-nonfree',
        }
    },

    'brainvisa-cortical-surface': {
        'alias': 'cortical-surface',
        'about': {
            'summary': 'BrainVISA toolbox fo cortex-based surfacic parameterization and analysis. Also contains the FreeSurfer toolbox for BrainVisa.',
            'license': 'GPL'
        },
        'packages': {
            'morphologist',
            'cortical_surface-gpl',
            'cortical_surface-nonfree',
            'brainvisa-freesurfer'
        }
    },

    'brainvisa-brainrat': {
        'about': {
            'summary': 'Ex vivo 3D reconstruction and analysis toolbox, from the <a href="http://www-dsv.cea.fr/dsv/instituts/institut-d-imagerie-biomedicale-i2bm/services/mircen-mircen/unite-cnrs-ura2210-lmn/fiches-thematiques/traitement-et-analyse-d-images-biomedicales-multimodales-du-cerveau-normal-ou-de-modeles-precliniques-de-maladies-cerebrales">BioPICSEL CEA team</a>. Homepage: <a href="http://brainvisa.info/doc/brainrat-gpl/brainrat_man/en/html/index.html">http://brainvisa.info/doc/brainrat-gpl/brainrat_man/en/html/index.html</a>',
        },
        'alias': 'brainrat',
        'packages': {
            'anatomist',
            'brainrat-gpl',
            'brainrat-private',
        }
    },

    'brainvisa-primatologist': {
        'alias': 'primatologist',
        'packages': {
            'anatomist',
            'primatologist-gpl',
        }
    },

    'brainvisa-opensource': {
        'alias': ['opensource'],
        'packages': {
            'anatomist',
            'brainvisa-cortical-surface',
            'brainvisa-base',
            'brainvisa-data-processing',
            'brainvisa-highres-cortex',
            'brainvisa-spm',
            'morphologist',
        },
    },

    'brainvisa': {
        'about': {
            'homepage': 'https://brainvisa.info',
            'license': 'GPL',
            'summary': 'Neuroimaging software platform for mass data analysis',
            'description': 'BrainVISA provides a complete, modular, infrastructure for neuroimaging software. It helps organizing heterogeneous software and data and provides a common general graphical interface for users. BrainVISA is thus a set of tools rather than a single software.'
        },
        'packages': {
            'brainvisa-opensource',
            'brainvisa-brainrat',
            'brainvisa-primatologist',
        },
    },
    
    'brainvisa-constellation': {
        'alias': 'constellation',
        'packages': {
            'morphologist',
            'constellation-gpl',
            'constellation-nonfree',
        }
    },

    'brainvisa-standard': {
        'alias': 'standard',
        'packages': {
            'brainvisa-opensource',
            'morphologist-baby'
        },
    },

    'brainvisa-cea': {
        'alias': 'cea',
        'packages': {
            'brainvisa',
            'brainvisa-constellation',
            'brainvisa-disco',
            'bioprocessing',
        }
    },

    'brainvisa-cati': {
        'alias': ['cati', 'cati_platform'],
        'packages': {
            'brainvisa-standard',
            'catidb-client',
            'deidentification',
            'longitudinal_pipelines',
            'nuclear_imaging-gpl',
            'nuclear_imaging-nonfree',
            'qualicati',
            'rsfmri',
            'sacha-gpl',
            'sacha-nonfree',
            'snapbase',
            'whasa-gpl',
            'whasa-nonfree'
        },
    },

    'brainvisa-3dns': {
        'alias': '3dns',
        'packages': {'3dns-private'},
    },
}


customize_components_definition = [os.path.expanduser('~/.brainvisa/components_definition.py')]
if 'BV_MAKER_BUILD' in os.environ:
    customize_components_definition.append(os.path.join(os.environ['BV_MAKER_BUILD'], 'components_definition.py'))
for ccd in customize_components_definition:
    if os.path.exists(ccd):
        with open(ccd) as f:
            exec(compile(f.read(), ccd, 'exec'))

# allow to name branches master or bug_fix indistinctly, or integration/trunk
for cgroup in components_definition:
    for comp in cgroup[1]['components']:
        branches = comp[1]['branches']
        if 'bug_fix' in branches and 'master' not in branches:
            branches['master'] = branches['bug_fix']
        elif 'master' in branches and 'bug_fix' not in branches:
            branches['bug_fix'] = branches['master']
        if 'trunk' in branches and 'integration' not in branches:
            branches['integration'] = branches['trunk']
        elif 'integration' in branches and 'trunk' not in branches:
            branches['trunk'] = branches['integration']

