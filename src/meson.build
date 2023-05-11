instances_sources = [
  'application.vala',
  'window.vala',
]

instances_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
]

gnome = import('gnome')

instances_sources += gnome.compile_resources('instances-resources',
  'instances.gresource.xml',
  c_name: 'instances'
)

executable('instances', instances_sources,
  vala_args: '--target-glib=2.50',  dependencies: instances_deps,
  install: true,
)
