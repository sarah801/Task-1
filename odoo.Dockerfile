
FROM odoo:16

USER root


COPY ./config/odoo.conf /etc/odoo/odoo.conf


COPY ./uc16_custom /mnt/extra-addons
COPY ./addons16_new /mnt/enterprise


RUN chown -R odoo:odoo /mnt/extra-addons /mnt/enterprise /etc/odoo


USER odoo

# Expose default Odoo port
EXPOSE 8069

# Command to run Odoo
CMD ["odoo", "--dev", "xml", "-c", "/etc/odoo/odoo.conf"]
