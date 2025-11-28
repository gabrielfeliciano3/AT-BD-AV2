-- Script para remover todas as triggers do banco de dados 'seed_go'

-- Triggers da tabela 'agricultores'
DROP TRIGGER IF EXISTS `seed_go`.`trg_after_agricultor_insert`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_after_agricultor_update`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_after_agricultor_delete`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_before_agricultor_insert_uppercase`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_before_agricultor_insert_cpf`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_before_agricultor_update_cpf`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_before_agricultor_delete`;

-- Triggers da tabela 'semente'
DROP TRIGGER IF EXISTS `seed_go`.`trg_before_semente_update`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_before_semente_delete`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_after_semente_insert`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_before_semente_insert_validade`;

-- Triggers da tabela 'distribuicoes'
DROP TRIGGER IF EXISTS `seed_go`.`trg_after_distribuicao_insert`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_before_distribuicao_insert`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_before_distribuicao_delete`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_before_distribuicao_insert_qtd`;

-- Triggers da tabela 'cultivos'
DROP TRIGGER IF EXISTS `seed_go`.`trg_after_cultivo_insert`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_after_cultivo_update`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_before_cultivo_update_data`;

-- Triggers da tabela 'usuarios'
DROP TRIGGER IF EXISTS `seed_go`.`trg_after_usuario_insert`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_before_usuario_insert_email`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_before_usuario_update_email`;

-- Triggers da tabela 'tecnicos'
DROP TRIGGER IF EXISTS `seed_go`.`trg_before_tecnico_delete`;
DROP TRIGGER IF EXISTS `seed_go`.`trg_after_tecnico_insert`;

-- Triggers da tabela 'rastreabilidade'
DROP TRIGGER IF EXISTS `seed_go`.`trg_after_rastreabilidade_insert`;

-- Triggers da tabela 'sincronizacoes'
DROP TRIGGER IF EXISTS `seed_go`.`trg_after_sincronizacao_insert`;

SELECT 'Todas as 25 triggers foram removidas com sucesso.' AS status;



-- 1. Trigger para registrar no histórico qualquer novo agricultor inserido.
DELIMITER $$
CREATE TRIGGER trg_after_agricultor_insert
AFTER INSERT ON agricultores
FOR EACH ROW
BEGIN
    INSERT INTO historico_registros (tabela, id_registro, acao, data_acao, usuarios_id_usuario)
    VALUES ('agricultores', NEW.id_agricultores, 'inserir', NOW(), 1); -- Usando ID 1 (admin) como padrão. Em um sistema real, seria o ID do usuário logado.
END$$
DELIMITER ;

-- 2. Trigger para registrar no histórico qualquer atualização nos dados de um agricultor.
DELIMITER $$
CREATE TRIGGER trg_after_agricultor_update
AFTER UPDATE ON agricultores
FOR EACH ROW
BEGIN
    INSERT INTO historico_registros (tabela, id_registro, acao, data_acao, usuarios_id_usuario)
    VALUES ('agricultores', NEW.id_agricultores, 'atualizar', NOW(), 1);
END$$
DELIMITER ;

-- 3. Trigger para registrar no histórico a exclusão de um agricultor.
DELIMITER $$
CREATE TRIGGER trg_after_agricultor_delete
AFTER DELETE ON agricultores
FOR EACH ROW
BEGIN
    INSERT INTO historico_registros (tabela, id_registro, acao, data_acao, usuarios_id_usuario)
    VALUES ('agricultores', OLD.id_agricultores, 'excluir', NOW(), 1);
END$$
DELIMITER ;

-- 4. Trigger para impedir que a quantidade de sementes em estoque se torne negativa.
DELIMITER $$
CREATE TRIGGER trg_before_semente_update
BEFORE UPDATE ON semente
FOR EACH ROW
BEGIN
    IF NEW.quat_disponivel < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: A quantidade de sementes não pode ser negativa.';
    END IF;
END$$
DELIMITER ;

-- 5. Trigger para registrar no histórico a inserção de uma nova distribuição.
DELIMITER $$
CREATE TRIGGER trg_after_distribuicao_insert
AFTER INSERT ON distribuicoes
FOR EACH ROW
BEGIN
    INSERT INTO historico_registros (tabela, id_registro, acao, data_acao, usuarios_id_usuario)
    VALUES ('distribuicoes', NEW.id_distribuicao, 'inserir', NOW(), 1);
END$$
DELIMITER ;

-- 6. Trigger para impedir a exclusão de uma semente que ainda tem estoque.
DELIMITER $$
CREATE TRIGGER trg_before_semente_delete
BEFORE DELETE ON semente
FOR EACH ROW
BEGIN
    IF OLD.quat_disponivel > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Não é possível excluir uma semente que ainda possui estoque.';
    END IF;
END$$
DELIMITER ;

-- 7. Trigger para garantir que a data de entrega de uma distribuição não seja no futuro.
DELIMITER $$
CREATE TRIGGER trg_before_distribuicao_insert
BEFORE INSERT ON distribuicoes
FOR EACH ROW
BEGIN
    IF NEW.data_entrega > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A data de entrega não pode ser uma data futura.';
    END IF;
END$$
DELIMITER ;

-- 8. Trigger para registrar a criação de um novo usuário no histórico.
DELIMITER $$
CREATE TRIGGER trg_after_usuario_insert
AFTER INSERT ON usuarios
FOR EACH ROW
BEGIN
    INSERT INTO historico_registros (tabela, id_registro, acao, data_acao, usuarios_id_usuario)
    VALUES ('usuarios', NEW.id_usuario, 'inserir', NOW(), 1);
END$$
DELIMITER ;

-- 9. Trigger para converter o nome do agricultor para maiúsculas antes de inserir.
DELIMITER $$
CREATE TRIGGER trg_before_agricultor_insert_uppercase
BEFORE INSERT ON agricultores
FOR EACH ROW
BEGIN
    SET NEW.nome = UPPER(NEW.nome);
END$$
DELIMITER ;

-- 10. Trigger para impedir que um técnico seja excluído se ele estiver associado a uma distribuição.
DELIMITER $$
CREATE TRIGGER trg_before_tecnico_delete
BEFORE DELETE ON tecnicos
FOR EACH ROW
BEGIN
    -- Esta é uma verificação simbólica, pois a FK com `ON DELETE NO ACTION` já faria isso.
    -- A trigger serve para fornecer uma mensagem de erro mais clara.
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Não é possível excluir um técnico associado a distribuições. Remova as associações primeiro.';
END$$
DELIMITER ;

-- 11. Trigger para registrar a criação de um novo cultivo no histórico.
DELIMITER $$
CREATE TRIGGER trg_after_cultivo_insert
AFTER INSERT ON cultivos
FOR EACH ROW
BEGIN
    INSERT INTO historico_registros (tabela, id_registro, acao, data_acao, usuarios_id_usuario)
    VALUES ('cultivos', NEW.idcultivos, 'inserir', NOW(), 1);
END$$
DELIMITER ;

-- 12. Trigger para validar o CPF do agricultor (verifica se tem 11 dígitos).
DELIMITER $$
CREATE TRIGGER trg_before_agricultor_insert_cpf
BEFORE INSERT ON agricultores
FOR EACH ROW
BEGIN
    IF CHAR_LENGTH(NEW.cpf) != 11 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CPF inválido. Deve conter exatamente 11 dígitos.';
    END IF;
END$$
DELIMITER ;
-- 13. Trigger para registrar no histórico a atualização de um cultivo.
DELIMITER $$
CREATE TRIGGER trg_after_cultivo_update
AFTER UPDATE ON cultivos
FOR EACH ROW
BEGIN
    INSERT INTO historico_registros (tabela, id_registro, acao, data_acao, usuarios_id_usuario)
    VALUES ('cultivos', NEW.idcultivos, 'atualizar', NOW(), 1);
END$$
DELIMITER ;

-- 14. Trigger para impedir a atualização do CPF de um agricultor.
DELIMITER $$
CREATE TRIGGER trg_before_agricultor_update_cpf
BEFORE UPDATE ON agricultores
FOR EACH ROW
BEGIN
    IF NEW.cpf != OLD.cpf THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Não é permitido alterar o CPF de um agricultor.';
    END IF;
END$$
DELIMITER ;

-- 15. Trigger para registrar no histórico a adição de uma nova semente.
DELIMITER $$
CREATE TRIGGER trg_after_semente_insert
AFTER INSERT ON semente
FOR EACH ROW
BEGIN
    INSERT INTO historico_registros (tabela, id_registro, acao, data_acao, usuarios_id_usuario)
    VALUES ('semente', NEW.id_semente, 'inserir', NOW(), 1);
END$$
DELIMITER ;

-- 16. Trigger para garantir que o e-mail de um usuário seja único.
DELIMITER $$
CREATE TRIGGER trg_before_usuario_insert_email
BEFORE INSERT ON usuarios
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM usuarios WHERE email = NEW.email) > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O e-mail fornecido já está em uso.';
    END IF;
END$$
DELIMITER ;

-- 17. Trigger para garantir que o e-mail de um usuário continue único ao ser atualizado.
DELIMITER $$
CREATE TRIGGER trg_before_usuario_update_email
BEFORE UPDATE ON usuarios
FOR EACH ROW
BEGIN
    IF NEW.email != OLD.email AND (SELECT COUNT(*) FROM usuarios WHERE email = NEW.email) > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O novo e-mail fornecido já está em uso.';
    END IF;
END$$
DELIMITER ;

-- 18. Trigger para registrar uma nova movimentação de rastreabilidade no histórico.
DELIMITER $$
CREATE TRIGGER trg_after_rastreabilidade_insert
AFTER INSERT ON rastreabilidade
FOR EACH ROW
BEGIN
    INSERT INTO historico_registros (tabela, id_registro, acao, data_acao, usuarios_id_usuario)
    VALUES ('rastreabilidade', NEW.id_rastreio, 'inserir', NOW(), 1);
END$$
DELIMITER ;

-- 19. Trigger para impedir que a data de validade de uma semente seja no passado.
DELIMITER $$
CREATE TRIGGER trg_before_semente_insert_validade
BEFORE INSERT ON semente
FOR EACH ROW
BEGIN
    IF NEW.data_validade < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A data de validade não pode ser uma data passada.';
    END IF;
END$$
DELIMITER ;

-- 20. Trigger para registrar a criação de um novo técnico no histórico.
DELIMITER $$
CREATE TRIGGER trg_after_tecnico_insert
AFTER INSERT ON tecnicos
FOR EACH ROW
BEGIN
    INSERT INTO historico_registros (tabela, id_registro, acao, data_acao, usuarios_id_usuario)
    VALUES ('tecnicos', NEW.idtecnicos, 'inserir', NOW(), 1);
END$$
DELIMITER ;

-- 21. Trigger para impedir a exclusão de uma distribuição se já houver um cultivo associado.
DELIMITER $$
CREATE TRIGGER trg_before_distribuicao_delete
BEFORE DELETE ON distribuicoes
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM cultivos WHERE distribuicoes_id_distribuicao = OLD.id_distribuicao) > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Não é possível excluir uma distribuição que já possui um registro de cultivo.';
    END IF;
END$$
DELIMITER ;

-- 22. Trigger para garantir que a quantidade entregue em uma distribuição seja maior que zero.
DELIMITER $$
CREATE TRIGGER trg_before_distribuicao_insert_qtd
BEFORE INSERT ON distribuicoes
FOR EACH ROW
BEGIN
    IF NEW.quantidade_entregue <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A quantidade entregue deve ser maior que zero.';
    END IF;
END$$
DELIMITER ;

-- 23. Trigger para registrar uma sincronização no histórico.
DELIMITER $$
CREATE TRIGGER trg_after_sincronizacao_insert
AFTER INSERT ON sincronizacoes
FOR EACH ROW
BEGIN
    INSERT INTO historico_registros (tabela, id_registro, acao, data_acao, usuarios_id_usuario)
    VALUES ('sincronizacoes', NEW.id_sync, 'inserir', NEW.usuarios_id_usuario);
END$$
DELIMITER ;

-- 24. Trigger para impedir que um agricultor seja excluído se ele tiver distribuições associadas.
DELIMITER $$
CREATE TRIGGER trg_before_agricultor_delete
BEFORE DELETE ON agricultores
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM distribuicoes WHERE agricultores_id_agricultores = OLD.id_agricultores) > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Não é possível excluir um agricultor que possui distribuições registradas.';
    END IF;
END$$
DELIMITER ;

-- 25. Trigger para atualizar a data de registro de um cultivo sempre que a descrição ou fase for modificada.
DELIMITER $$
CREATE TRIGGER trg_before_cultivo_update_data
BEFORE UPDATE ON cultivos
FOR EACH ROW
BEGIN
    IF NEW.descricao != OLD.descricao OR NEW.fase_crescimento != OLD.fase_crescimento THEN
        SET NEW.data_registro = CURDATE();
    END IF;
END$$
DELIMITER ;
-- Teste 1: Inserir um novo agricultor (deve ter o nome em maiúsculas e registrar no histórico)
-- Ativa: trg_before_agricultor_insert_uppercase, trg_after_agricultor_insert, trg_before_agricultor_insert_cpf
INSERT INTO agricultores (nome, cpf, endereco, telefone, email, registro_ipa, data_cadastro)
VALUES ('Teste Trigger', '11122233344', 'Rua Teste, 123', '81912345678', 'teste@trigger.com', 'IPA999', CURDATE());

-- Verifique se o nome foi salvo em maiúsculas e se um registro foi adicionado em `historico_registros`
SELECT * FROM agricultores WHERE nome = 'TESTE TRIGGER';
SELECT * FROM historico_registros WHERE tabela = 'agricultores' AND acao = 'inserir' ORDER BY idhistorico_registros DESC LIMIT 1;

-- Teste 2: Tentar inserir uma distribuição com data futura (deve falhar)
-- Ativa: trg_before_distribuicao_insert
INSERT INTO distribuicoes (quantidade_entregue, data_entrega, responsavel_entrega, status_sync, agricultores_id_agricultores, semente_id_semente)
VALUES (50.0, '2028-12-31', 'Teste', 0, 1, 1);
-- >> Este comando deve retornar o erro: "A data de entrega não pode ser uma data futura."

-- Teste 3: Tentar atualizar o estoque de uma semente para um valor negativo (deve falhar)
-- Ativa: trg_before_semente_update
UPDATE semente SET quat_disponivel = -10 WHERE id_semente = 1;
-- >> Este comando deve retornar o erro: "A quantidade de sementes não pode ser negativa."

-- Teste 4: Tentar inserir um agricultor com CPF inválido (deve falhar)
-- Ativa: trg_before_agricultor_insert_cpf
INSERT INTO agricultores (nome, cpf, endereco, telefone, email, registro_ipa, data_cadastro)
VALUES ('CPF Invalido', '123', 'Rua Invalida, 0', '81900000000', 'cpf@invalido.com', 'IPA000', CURDATE());
-- >> Este comando deve retornar o erro: "CPF inválido. Deve conter exatamente 11 dígitos."

-- Teste 5: Excluir o agricultor de teste que criamos (deve registrar no histórico)
-- Ativa: trg_after_agricultor_delete
DELETE FROM agricultores WHERE nome = 'TESTE TRIGGER';

-- Verifique se a exclusão foi registrada no histórico
SELECT * FROM historico_registros WHERE tabela = 'agricultores' AND acao = 'excluir' ORDER BY idhistorico_registros DESC LIMIT 1;

-- Teste 13: Tentar atualizar o CPF de um agricultor (deve falhar)
-- Ativa: trg_before_agricultor_update_cpf
UPDATE agricultores SET cpf = '99988877766' WHERE id_agricultores = 1;
-- >> Este comando deve retornar o erro: "Não é permitido alterar o CPF de um agricultor."

-- Teste 14: Tentar inserir um usuário com um e-mail que já existe (deve falhar)
-- Ativa: trg_before_usuario_insert_email
INSERT INTO usuarios (nome_usuario, email, senha_hash, tipo_usuario, ativo)
VALUES ('Usuário Duplicado', 'admin1@ipa.com', 'hash_duplicado', 'tecnico', 1);
-- >> Este comando deve retornar o erro: "O e-mail fornecido já está em uso."

-- Teste 15: Tentar inserir uma semente com data de validade no passado (deve falhar)
-- Ativa: trg_before_semente_insert_validade
INSERT INTO semente (nome_semente, tipo_cultura, lote, data_validade, origem, quat_disponivel)
VALUES ('Semente Vencida', 'Teste', 'L999', '2020-01-01', 'Origem Teste', 100);
-- >> Este comando deve retornar o erro: "A data de validade não pode ser uma data passada."

-- Teste 16: Tentar excluir uma distribuição que tem um cultivo associado (deve falhar)
-- Ativa: trg_before_distribuicao_delete
-- Primeiro, encontre uma distribuição que tenha um cultivo. A distribuição com id 1 tem.
DELETE FROM distribuicoes WHERE id_distribuicao = 1;
-- >> Este comando deve retornar o erro: "Não é possível excluir uma distribuição que já possui um registro de cultivo."

-- Teste 17: Tentar inserir uma distribuição com quantidade zero (deve falhar)
-- Ativa: trg_before_distribuicao_insert_qtd
INSERT INTO distribuicoes (quantidade_entregue, data_entrega, responsavel_entrega, status_sync, agricultores_id_agricultores, semente_id_semente)
VALUES (0, CURDATE(), 'Teste Qtd', 0, 1, 2);
-- >> Este comando deve retornar o erro: "A quantidade entregue deve ser maior que zero."
